//
//  ViewController.swift
//  WKWebViewBridgeExample
//
//  Created by Priya Rajagopal on 12/8/14.
//  Copyright (c) 2014 Lunaria Software LLC. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {
    var webView: WKWebView?
    var buttonClicked:Int = 0
    var colors:[String] = ["0xff00ff","#ff0000","#ffcc00"];
    var webConfig:WKWebViewConfiguration {
        get {
            
                // Create WKWebViewConfiguration instance
                let webCfg:WKWebViewConfiguration = WKWebViewConfiguration()
                
                // Setup WKUserContentController instance for injecting user script
                let userController:WKUserContentController = WKUserContentController()
                
                // Add a script message handler for receiving  "buttonClicked" event notifications posted from the JS document using window.webkit.messageHandlers.buttonClicked.postMessage script message
            userController.add(self, name: "buttonClicked")
            
                // Get script that's to be injected into the document
                let js:String = buttonClickEventTriggeredScriptToAddToDocument()
                
                // Specify when and where and what user script needs to be injected into the web document
            let userScript:WKUserScript =  WKUserScript(source: js, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: false)
            
                // Add the user script to the WKUserContentController instance
                userController.addUserScript(userScript)
            
                // Configure the WKWebViewConfiguration instance with the WKUserContentController
                webCfg.userContentController = userController;
            
            return webCfg;
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        // Create a WKWebView instance
        webView = WKWebView (frame: self.view.frame, configuration: webConfig)
        
        // Delegate to handle navigation of web content
        webView!.navigationDelegate = self
        
        view.addSubview(webView!)
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
                
        // Load the HTML document
        loadHtml()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        let fileName:String =  String("\( ProcessInfo.processInfo.globallyUniqueString)_TestFile.html")
        
        let tempHtmlPath:String =  NSTemporaryDirectory().appending(fileName)
        try? FileManager.default.removeItem(atPath: tempHtmlPath)
        
        webView = nil
     
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // WKNavigationDelegate
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog("%s", #function)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        debugPrint("%s. With Error %@", #function,error)
        showAlertWithMessage(message: "Failed to load file with error \(error.localizedDescription)!")
    }
    
    
    // File Loading
    func loadHtml() {
        // NOTE: Due to a bug in webKit as of iOS 8.1.1 we CANNOT load a local resource when running on device. Once that is fixed, we can get rid of the temp copy
        let mainBundle:Bundle = Bundle(for: ViewController.self)
        
        let fileName:String =  String("\( ProcessInfo.processInfo.globallyUniqueString)_TestFile.html")
        
        let tempHtmlPath:String? = NSTemporaryDirectory().appending(fileName)
        
        if let htmlPath = mainBundle.path(forResource: "TestFile", ofType: "html") {
            try? FileManager.default.copyItem(atPath: htmlPath, toPath: tempHtmlPath!)
            if tempHtmlPath != nil {
                let requestUrl = URLRequest(url: URL(fileURLWithPath: tempHtmlPath!) as URL)
                webView?.load(requestUrl as URLRequest)
            }
        }
        else {
            showAlertWithMessage(message: "Could not load HTML File!")
        }

    }
    
    // Button Click Script to Add to Document
    func buttonClickEventTriggeredScriptToAddToDocument() ->String{
        // Script: When window is loaded, execute an anonymous function that adds a "click" event handler function to the "ClickMeButton" button element. The "click" event handler calls back into our native code via the window.webkit.messageHandlers.buttonClicked.postMessage call
        var script:String?
        
        if let filePath:String = Bundle(for: ViewController.self).path(forResource: "ClickMeEventRegister", ofType:"js") {
        
            script = try? String(contentsOfFile: filePath, encoding: .utf8)
        }
        return script!;
        
    }
    
    // WKScriptMessageHandler Delegate
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        if let messageBody:NSDictionary = message.body as? NSDictionary {
            let idOfTappedButton:String = messageBody["ButtonId"] as! String
            updateColorOfButtonWithId(buttonId: idOfTappedButton)
        }
        
    }

    
    // Update color of Button with specified Id
    func updateColorOfButtonWithId(buttonId:String) {
        let count:UInt32 = UInt32(colors.count)
        let index:Int = Int(arc4random_uniform(count))
        let color:String = colors [index]
        
         // Script that changes the color of tapped button
        let js2:String = String(format: "var button = document.getElementById('%@'); button.style.backgroundColor='%@';", buttonId,color)
        
        webView?.evaluateJavaScript(js2, completionHandler: { (AnyObject, NSError) -> Void in
            debugPrint(#function)

        })
    }
    
    // Helper
    func showAlertWithMessage(message:String) {
        let alertAction:UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (UIAlertAction) -> Void in
            self.dismiss(animated: true, completion: { () -> Void in
                
            })
        }
        
        let alertView:UIAlertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertView.addAction(alertAction)
        
        self.present(alertView, animated: true, completion: { () -> Void in
            
        })
    }
   

}

