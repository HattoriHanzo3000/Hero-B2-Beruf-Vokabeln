//
//  MailComposeView.swift
//  B2 Berufssprachkurs
//
//  SwiftUI bridge for presenting MFMailComposeViewController.
//  Created: 24.11.25.
//

import SwiftUI
import MessageUI

// MARK: - MailComposeView

struct MailComposeView: UIViewControllerRepresentable {
    let subject: String
    let messageBody: String
    let toRecipients: [String]
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setSubject(subject)
        composer.setMessageBody(messageBody, isHTML: false)
        composer.setToRecipients(toRecipients)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onDismiss: () -> Void
        
        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true) {
                self.onDismiss()
            }
        }
    }
}
