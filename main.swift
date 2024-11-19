//
//  main.swift
//  PQHDR_to_GainMapHDR
//  This code will convert PQ HDR file to luminance gain map HDR heic file.
//
//  Created by Luyao Peng on 2024/9/27.
//

import CoreImage
import Foundation

let ctx = CIContext()


let arguments = CommandLine.arguments
guard arguments.count > 2 else {
    print("Usage: PQHDRtoGMHDR <source file> <destination folder> <options>\n       options:\n         -q <value>: image quality (default: 0.85)\n         -c <color space>: specify output color space (srgb, p3, rec2020)\n         -s: export tone mapped SDR image without HDR gain map\n         -p: export 10bit PQ HDR heic image")
    exit(1)
}

let url_hdr = URL(fileURLWithPath: arguments[1])
let filename = url_hdr.deletingPathExtension().appendingPathExtension("heic").lastPathComponent
let path_export = URL(fileURLWithPath: arguments[2])
let url_export_heic = path_export.appendingPathComponent(filename)
let imageoptions = arguments.dropFirst(3)

var imagequality: Double? = 0.85
var sdr_export: Bool = false
var pq_export: Bool = false
var color_space_list = ["srgb","p3","rec2020"]

let hdr_image = CIImage(contentsOf: url_hdr, options: [.expandToHDR: true])
let tonemapped_sdrimage = hdr_image?.applyingFilter("CIToneMapHeadroom", parameters: ["inputTargetHeadroom":1.0])
let export_options = NSDictionary(dictionary:[kCGImageDestinationLossyCompressionQuality:imagequality ?? 0.85, CIImageRepresentationOption.hdrImage:hdr_image!])

var sdr_color_space = CGColorSpace.displayP3
var hdr_color_space = CGColorSpace.displayP3_PQ

let image_color_space = hdr_image?.colorSpace?.name
if (image_color_space! as NSString).contains("709") {
    sdr_color_space = CGColorSpace.itur_709
    hdr_color_space = CGColorSpace.itur_709_PQ
}
if (image_color_space! as NSString).contains("sRGB") {
    sdr_color_space = CGColorSpace.itur_709
    hdr_color_space = CGColorSpace.itur_709_PQ
}
if (image_color_space! as NSString).contains("2100") {
    sdr_color_space = CGColorSpace.itur_2020_sRGBGamma
    hdr_color_space = CGColorSpace.itur_2100_PQ
}
if (image_color_space! as NSString).contains("2020") {
    sdr_color_space = CGColorSpace.itur_2020_sRGBGamma
    hdr_color_space = CGColorSpace.itur_2100_PQ
}

var index:Int = 0
while index < imageoptions.count {
    let option = arguments[index+3]
    switch option {
    case "-q": // Handle -q <value> option
        // Check if there is a next value in the array
        guard index + 1 < imageoptions.count else {
            print("Error: The -q option requires a numeric value.")
            exit(1)
        }
        if let value = Double(arguments[index + 4]) {
            if value > 1 {
                imagequality = value/100
            } else {
                imagequality = value
            }
            index += 1 // Skip the next value
        } else {
            print("Error: The -q option must be followed by a valid numeric value.")
            exit(1)
        }
    case "-s":
        if pq_export {
            print("Error: Only one type of export can be specified.")
            exit(1)
        }
        sdr_export = true
    case "-p":
        if sdr_export {
            print("Error: Only one type of export can be specified.")
            exit(1)
        }
        pq_export = true
    case "-c":
        guard index + 1 < imageoptions.count else {
            print("Error: The -c option requires color space argument.")
            exit(1)
        }
        let color_space_argument = String(arguments[index + 4])
        let color_space_option = color_space_argument.lowercased()
        if color_space_list.contains(color_space_option){
            switch color_space_option {
                case "srgb":
                sdr_color_space = CGColorSpace.itur_709
                hdr_color_space = CGColorSpace.itur_709_PQ
                case "p3":
                sdr_color_space = CGColorSpace.displayP3
                hdr_color_space = CGColorSpace.displayP3_PQ
                case "rec2020":
                sdr_color_space = CGColorSpace.itur_2020_sRGBGamma
                hdr_color_space = CGColorSpace.itur_2100_PQ
            default:
                print("Error: The -c option requires color space argument. (srgb, p3, rec2020)")
                exit(1)
            }
        }
        index += 1 // Skip the next value
    default:
        print("Unknown option: \(option)")
    }
    index += 1
}



while sdr_export {
    let sdr_export_options = NSDictionary(dictionary:[kCGImageDestinationLossyCompressionQuality:imagequality ?? 0.85])
    try! ctx.writeHEIFRepresentation(of: tonemapped_sdrimage!,
                                     to: url_export_heic,
                                     format: CIFormat.RGBA8,
                                     colorSpace: CGColorSpace(name: sdr_color_space)!,
                                     options:sdr_export_options as! [CIImageRepresentationOption : Any])
    exit(0)
}

while pq_export {
    let pq_export_options = NSDictionary(dictionary:[kCGImageDestinationLossyCompressionQuality:imagequality ?? 0.85])
    try! ctx.writeHEIF10Representation(of: hdr_image!,
                                       to: url_export_heic,
                                       colorSpace: CGColorSpace(name: hdr_color_space)!,
                                       options:pq_export_options as! [CIImageRepresentationOption : Any])
    exit(0)
}

try! ctx.writeHEIFRepresentation(of: tonemapped_sdrimage!,
                                 to: url_export_heic,
                                 format: CIFormat.RGBA8,
                                 colorSpace: CGColorSpace(name: sdr_color_space)!,
                                 options: export_options as! [CIImageRepresentationOption : Any])
exit(0)
// debug
//let filename2 = url_hdr.deletingPathExtension().appendingPathExtension("png").lastPathComponent
//let url_export_heic2 = path_export.appendingPathComponent(filename2)
//try! ctx.writePNGRepresentation(of: gainmap!, to: url_export_heic2, format: CIFormat.RGBA8, colorSpace:CGColorSpace(name: CGColorSpace.displayP3)!)


