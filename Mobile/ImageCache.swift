//
//  ImageCache.swift
//  Mobile
//
//  Created by Jason Hocker on 5/18/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

class ImageCache : NSObject {
   
    static let sharedCache = ImageCache()
    
    var cachePath : String?
    
    private override init() {
        super.init()
        self.createCacheDirectory()
        
        NotificationCenter.default.addObserver(self, selector: #selector(configurationLoading(_:)), name: ConfigurationManager.ConfigurationLoadStartedNotification, object: nil)

    }
    
    func createCacheDirectory() {
        self.cachePath = nil
        let fm: FileManager = FileManager.default
        var paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        if paths.count > 0 {
            let bundleName = (Bundle.main.infoDictionary!["CFBundleIdentifier"] as! String)
            self.cachePath = (paths[0] as NSString).appendingPathComponent(bundleName)
            if let cachePath = self.cachePath {
                do {
                    try fm.createDirectory(atPath: cachePath, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("unable to create directory: %@", error)
                }
            }
        }
    }
    
    @objc private func configurationLoading(_ notification: Notification) {
        reset()
    }

    
    //remove all images from cache
    func reset() {
        print("ImageCache reset - deleting all cached images")
        let fm: FileManager = FileManager.default
        //remove directory and its contents
        if let cachePath = self.cachePath {
            do{
                try fm.removeItem(atPath: cachePath)
            } catch {
                print("Unable to clear cache: %@", error)
            }
        }
        //restore directory after deletion
        self.createCacheDirectory()
    }

    func cacheImageForLater(_ filename: String, dispatchGroup: DispatchGroup?=nil) {
        let uiImage = getCachedImage(filename)
        if uiImage == nil {
            getImage(filename, dispatchGroup: dispatchGroup) {
                (image: UIImage?) in
                // do nothing
            }
        }
    }

    func getImage(_ filename: String, dispatchGroup: DispatchGroup?=nil, completionHandler:  @escaping (_ image: UIImage?) -> Void) {
        var uiImage:UIImage? = nil
        var completionHandled = false
        
        if !filename.isEmpty {
            uiImage = getCachedImage(filename)
            if uiImage == nil {
                completionHandled = true
                if dispatchGroup != nil {
                    dispatchGroup!.enter()
                }
                downloadImage(filename) {
                    (image: UIImage?) in
                    
                    completionHandler(image)
                    if dispatchGroup != nil {
                        dispatchGroup!.leave()
                    }
                }
            }
        }

        if !completionHandled {
            completionHandler(uiImage)
        }
    }
    
    func getCachedImage(_ filename: String) -> UIImage? {
        var uiImage:UIImage? =  nil
        let encodedName: String = filename.sha1()
        // Generates a unique path to a resource representing the image
        if let cachePath = self.cachePath {
            let uniquePath = "\(cachePath)/\(encodedName)"
            // Check for file existence
            //print("Checking for cached image encodedName: \(encodedName) atPath: \(uniquePath)")
            if FileManager.default.fileExists(atPath: uniquePath) {
                //print("found cached file encodedName: \(encodedName)")
                uiImage = UIImage(contentsOfFile: uniquePath)
            }
        }
        
        return uiImage
    }
    
    func downloadImage(_ filename: String, completionHandler: @escaping (_ image: UIImage?) -> Void) {
        var completionHandled = false

        let encodedName: String = filename.sha1()
        if let imageURL: URL = URL(string: filename) {
            // Generates a unique path to a resource representing the image
            if let cachePath = self.cachePath {
                let uniquePath = "\(cachePath)/\(encodedName)"
                // Check for file existence
                // download image and store it
                let urlSession = URLSession.shared
                completionHandled = true
                //print("downloading image: \(imageURL)")
                var urlRequest = URLRequest(url: imageURL)
                completionHandled = true
                let downloadTask = urlSession.ellucianDownloadTask(with: &urlRequest) {
                    (location, urlResponse, downloadError) -> Void in
                    
                    var successfullyCached = false
                    if location != nil {
                        let fileManager = FileManager.default
                        // success
                        // move the file to the desired location
                        // could have been loaded already - check again
                        if !fileManager.fileExists(atPath: uniquePath) {
                            print("moving downloaded image to encodedName: \(encodedName) from: \(location!.path) to: \(uniquePath)")
                            do {
                                try FileManager.default.moveItem(atPath: location!.path, toPath: uniquePath)
                                successfullyCached = true
                            } catch {
                                // failed to move, maybe another request beat this one
                                if fileManager.fileExists(atPath: uniquePath) {
                                    // yep, return a UIImage to the uniquePath
                                    successfullyCached = true
                                } else {
                                    // some other error case
                                    print("Unable move encodedName: \(encodedName) error: \(error)")
                                    let downloadedFileExists = fileManager.fileExists(atPath: location!.path)
                                    let destinationFileExists = fileManager.fileExists(atPath: location!.path)
                                    print("Source exists: \(downloadedFileExists)")
                                    print("Destination exists: \(destinationFileExists)")
                                }
                            }
                        } else {
                            successfullyCached = true
                        }
                        
                        DispatchQueue.main.async {
                            if successfullyCached {
                                if let result = UIImage(contentsOfFile: uniquePath) {
                                    print("image is in the cache - encodedName: \(encodedName) uiImage: \(result)")
                                    completionHandler(result)
                                } else {
                                    print("image is in the cache - encodedName: \(encodedName) ")
                                    completionHandler(nil)
                                }
                            }
                            
                            
                        }
                    } else if let downloadError = downloadError {
                        print("Download failed for encodedName: \(encodedName) error: \(downloadError)")
                        completionHandler(nil)
                    }
                }
                downloadTask.resume()
            }
        }
        
        if !completionHandled {
            completionHandler(nil)
        }
    }

}
