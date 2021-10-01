//
//  MosaicProcessingViewController.swift
//  ImageProcessor
//
//  Created by Masato Takamura on 2021/09/28.
//

import UIKit
import AVFoundation

final class ImageProcessingViewController: UIViewController {

    private let  baseImage = UIImage()

    //画像の辺の長さ
    private let imageSize: CGFloat = 400

    //縮小率10%
    private let reductionRate: CGFloat = 0.1

    private var filterValue: Float = 0

    private let context = CIContext()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .black
        return imageView
    }()

    private lazy var mosaicButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .lightGray
        button.setTitleColor(.white, for: .normal)
        button.setTitle("モザイク", for: .normal)
        button.layer.cornerRadius = 10
        button.addTarget(
            self,
            action: #selector(didTapMosaicButton(_:)),
            for: .touchUpInside
        )
        return button
    }()

    private lazy var slider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 20
        slider.isContinuous = true

        slider.addTarget(
            self,
            action: #selector(changeSliderValue(_:)), for: .valueChanged)
        return slider
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayoutConstraint()

    }

    private func setupLayoutConstraint() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.heightAnchor.constraint(equalToConstant: imageSize),
            imageView.widthAnchor.constraint(equalToConstant: imageSize)
        ])

        mosaicButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mosaicButton)
        NSLayoutConstraint.activate([
            mosaicButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 32),
            mosaicButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mosaicButton.heightAnchor.constraint(equalToConstant: 40),
            mosaicButton.widthAnchor.constraint(equalToConstant: 200)
        ])

        slider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slider)
        NSLayoutConstraint.activate([
            slider.topAnchor.constraint(equalTo: mosaicButton.bottomAnchor, constant: 16),
            slider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            slider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            slider.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    @objc
    private func changeSliderValue(_ sender: UISlider) {
        filterValue = sender.value
        imageFilter()
    }

    @objc
    private func didTapMosaicButton(_ sender: UIButton) {
        //CALayerによる処理
        let mosaicAnimation = CABasicAnimation(keyPath: "rasterizationScale")
        mosaicAnimation.fromValue = 1.0
        mosaicAnimation.toValue = 0.1
        mosaicAnimation.duration = 5.0
        mosaicAnimation.isRemovedOnCompletion = false
        mosaicAnimation.fillMode = .forwards

        imageView.layer.shouldRasterize = true
        imageView.layer.minificationFilter = .trilinear
        imageView.layer.magnificationFilter = .nearest

        imageView.layer.add(mosaicAnimation, forKey: "mosaicAnimation")

    }

    private func imageFilter() {
        //UIImageをCIImageに変換して入力とする
        let inputCiImage = CIImage(image: baseImage)
        //画像にかけるフィルターの作成。今回はぼかし。処理ごとに作成する必要あり。
        let filter = CIFilter(name: "CIGaussianBlur")
        //フィルターをかける画像を設定
        filter?.setValue(inputCiImage, forKey: kCIInputImageKey)
        //フィルターの値を設定。kCIInputRadiusKeyはぼかしを入れるときのキー
        filter?.setValue(filterValue, forKey: kCIInputRadiusKey)
        //フィルター効果を表すをCIImageオブジェクトとして取得
        let cropRect = CGRect(x: 0, y: 0, width: (inputCiImage?.extent.width)!, height: (inputCiImage?.extent.height)!)
        let outputImage = filter?.outputImage?.cropped(to: cropRect).resize(as: (inputCiImage?.extent.size)!)

        let image = UIImage(cgImage: context.createCGImage(outputImage!, from: outputImage!.extent)!)

        imageView.image = image
    }

    ///UIGraphicsによるモザイク処理
    ///縮んでから拡大するため、途中のドットが抜けてモザイクっぽくなる
//    private func shrinkAndExpand(image: UIImage) {
//        //縮小開始
//        UIGraphicsBeginImageContext(CGSize(width: imageSize * reductionRate, height: imageSize * reductionRate))
//        // 元画像を10%に縮小
//        image.draw(in: CGRect(x: CGFloat(0), y: CGFloat(0),
//                              width: imageSize * reductionRate, height: imageSize * reductionRate))
//        // 縮小した画像をnewImageとする
//        let reductionImage = UIGraphicsGetImageFromCurrentImageContext()
//        // 縮小完了
//        UIGraphicsEndImageContext()
//
//        //拡大開始
//        UIGraphicsBeginImageContext(CGSize(width: imageSize, height: imageSize));
//        // 縮小した画像を元サイズに拡大(=> x10)
//        reductionImage?.draw(in: CGRect(x: CGFloat(0), y: CGFloat(0),
//                                        width: imageSize, height: imageSize))
//        // 拡大した画像をimg3とする
//        let expansionImage = UIGraphicsGetImageFromCurrentImageContext()
//        //拡大完了
//        UIGraphicsEndImageContext()
//
//        imageView.image = expansionImage
//    }
}

extension CIImage {
    func resize(as size: CGSize) -> CIImage {
        let selfSize = extent.size
        let transform = CGAffineTransform(
            scaleX: size.width / selfSize.width,
            y: size.height / selfSize.height
        )
        return transformed(by: transform)
    }
}
