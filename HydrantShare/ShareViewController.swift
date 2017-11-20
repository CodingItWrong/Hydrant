//
//  ShareViewController.swift
//  HydrantShare
//
//  Created by Josh Justice on 11/20/17.
//  Copyright © 2017 NeedBee. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }
    
    private func getURLAttachment(completion: @escaping (URL) -> Void) {
        let item: NSExtensionItem = extensionContext!.inputItems[0] as! NSExtensionItem
        let attachment = item.attachments![0] as! NSItemProvider
        let urlType = kUTTypeURL as String
        let plainTextType = kUTTypePlainText as String
        if attachment.hasItemConformingToTypeIdentifier(urlType) {
            attachment.loadItem(forTypeIdentifier: urlType) { (data, error) in
                switch data {
                case let url as URL:
                    // todo: figure out how to pass IUO error
                    completion(url)
                default:
                    // TODO: call completion to finish the share event
                    NSLog("no url found")
                }
            }
        } else if attachment.hasItemConformingToTypeIdentifier(plainTextType) {
            attachment.loadItem(forTypeIdentifier: plainTextType) { (data, error) in
                switch data {
                case let urlString as String:
                    if let url = URL(string: urlString) {
                        completion(url)
                    } else {
                        // TODO: call completion to finish the share event
                        NSLog("String was not a URL")
                    }
                default:
                    // TODO: call completion to finish the share event
                    NSLog("no url found")
                }
            }
        }
    }

    private func postWebhook(bodyDict: [String: String?], completion: @escaping () -> Void) {
        let webhookURLString = "https://links.codingitwrong.com/webhooks/hydrant"
        let webhookURL = URL(string: webhookURLString)!
        let session = URLSession.shared
        var request = URLRequest(url: webhookURL)
        let bodyData = try! JSONSerialization.data(withJSONObject: bodyDict, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST";
        request.httpBody = bodyData;
        
        let task = session.dataTask(with: request) { data, response, error in
            guard error == nil else {
                self.alert(message: error!.localizedDescription, completion: completion)
                return
            }
            
            guard let response = response,
                  let httpResponse = response as? HTTPURLResponse else {
                self.alert(message: "Unexpected response type received", completion: completion)
                return
            }
            
            guard httpResponse.statusCode == 201 else {
                self.alert(message: "Unexpected response: \(httpResponse.statusCode)", completion: completion)
                return
            }
            
            self.alert(message: "Saved to Firehose.", completion: completion)
        }
        task.resume()
    }
    
    private func alert(message: String, completion: (() -> Void)?) {
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            completion?();
        }
        alert.addAction(okAction)
        self.present(alert, animated: true)
    }
    
    private func done() {
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    override func didSelectPost() {
        getURLAttachment() { sharedURL in
            let bodyDict = [
                "url": sharedURL.absoluteString,
                "title": self.contentText,
                ]
            self.postWebhook(bodyDict: bodyDict, completion: self.done)
        }
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

}

