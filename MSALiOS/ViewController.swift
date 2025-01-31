//
//  ViewController.swift
//  MsalApp1
//
//  Created by Raheem Chisman 1/2/2025
//

import UIKit
import MSAL
import IntuneMAMSwift

class ViewController: UIViewController {

    let kClientID = "<ClientId Here>"     // Update this to your client ID.
    let kGraphEndpoint = "https://graph.microsoft.com/" // the Microsoft Graph endpoint
    let kAuthority = "https://login.microsoftonline.com/common" // this authority allows a personal Microsoft account and a work or school account in any organization's Azure AD tenant to sign in

    let kScopes: [String] = ["user.read"] // request permission to read the profile of the signed-in user

    var accessToken = String()
    var applicationContext : MSALPublicClientApplication?
    var webViewParameters : MSALWebviewParameters?
    var currentAccount: MSALAccount?
    
    var loggingText: UITextView!
    var signOutButton: UIButton!
    var callGraphButton: UIButton!
    var usernameLabel: UILabel!
    
    
    
    var registerEnrollButton: UIButton!
    var UnEnrollButton: UIButton!

    func initUI() {

        usernameLabel = UILabel()
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.text = ""
        usernameLabel.textColor = .darkGray
        usernameLabel.textAlignment = .right

        self.view.addSubview(usernameLabel)

        usernameLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 50.0).isActive = true
        usernameLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10.0).isActive = true
        usernameLabel.widthAnchor.constraint(equalToConstant: 300.0).isActive = true
        usernameLabel.heightAnchor.constraint(equalToConstant: 50.0).isActive = true

        // Add call Graph button
        callGraphButton  = UIButton()
        callGraphButton.translatesAutoresizingMaskIntoConstraints = false
        callGraphButton.setTitle("Call Microsoft Graph API", for: .normal)
        callGraphButton.setTitleColor(.blue, for: .normal)
        callGraphButton.addTarget(self, action: #selector(callGraphAPI(_:)), for: .touchUpInside)
        self.view.addSubview(callGraphButton)

        callGraphButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        callGraphButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 120.0).isActive = true
        callGraphButton.widthAnchor.constraint(equalToConstant: 300.0).isActive = true
        callGraphButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true

        // Add sign out button
        signOutButton = UIButton()
        signOutButton.translatesAutoresizingMaskIntoConstraints = false
        signOutButton.setTitle("Sign Out", for: .normal)
        signOutButton.setTitleColor(.blue, for: .normal)
        signOutButton.setTitleColor(.gray, for: .disabled)
        signOutButton.addTarget(self, action: #selector(signOut(_:)), for: .touchUpInside)
        self.view.addSubview(signOutButton)

        signOutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signOutButton.topAnchor.constraint(equalTo: callGraphButton.bottomAnchor, constant: 10.0).isActive = true
        signOutButton.widthAnchor.constraint(equalToConstant: 150.0).isActive = true
        signOutButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true

        let deviceModeButton = UIButton()
        deviceModeButton.translatesAutoresizingMaskIntoConstraints = false
        deviceModeButton.setTitle("Get device info", for: .normal);
        deviceModeButton.setTitleColor(.blue, for: .normal);
        deviceModeButton.addTarget(self, action: #selector(getDeviceMode(_:)), for: .touchUpInside)
        self.view.addSubview(deviceModeButton)

        deviceModeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        deviceModeButton.topAnchor.constraint(equalTo: signOutButton.bottomAnchor, constant: 10.0).isActive = true
        deviceModeButton.widthAnchor.constraint(equalToConstant: 150.0).isActive = true
        deviceModeButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true

        
        ////  Add enroll button
        registerEnrollButton = UIButton()
        registerEnrollButton.translatesAutoresizingMaskIntoConstraints = false
        registerEnrollButton.setTitle("Enroll", for: .normal)
        registerEnrollButton.setTitleColor(.blue, for: .normal)
        registerEnrollButton.setTitleColor(.gray, for: .disabled)
        registerEnrollButton.addTarget(self, action: #selector(registerEnroll(_:)), for: .touchUpInside)
        self.view.addSubview(registerEnrollButton)
        
        registerEnrollButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        registerEnrollButton.topAnchor.constraint(equalTo: deviceModeButton.bottomAnchor, constant: 10.0).isActive = true
        registerEnrollButton.widthAnchor.constraint(equalToConstant: 150.0).isActive = true
        registerEnrollButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        
        ////  Add Unenroll button
        UnEnrollButton = UIButton()
        UnEnrollButton.translatesAutoresizingMaskIntoConstraints = false
        UnEnrollButton.setTitle("Unenroll", for: .normal)
        UnEnrollButton.setTitleColor(.blue, for: .normal)
        UnEnrollButton.setTitleColor(.gray, for: .disabled)
        UnEnrollButton.addTarget(self, action: #selector(UnEnroll(_:)), for: .touchUpInside)
        self.view.addSubview(UnEnrollButton)
        
        UnEnrollButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        UnEnrollButton.topAnchor.constraint(equalTo: registerEnrollButton.bottomAnchor, constant: 10.0).isActive = true
        UnEnrollButton.widthAnchor.constraint(equalToConstant: 150.0).isActive = true
        UnEnrollButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        
        ////  Add logging textfield
        loggingText = UITextView()
        loggingText.isUserInteractionEnabled = false
        loggingText.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(loggingText)

        loggingText.topAnchor.constraint(equalTo: UnEnrollButton.bottomAnchor, constant: 10.0).isActive = true
        loggingText.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 10.0).isActive = true
        loggingText.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -10.0).isActive = true
        loggingText.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 10.0).isActive = true
    }

    func platformViewDidLoadSetup() {

        NotificationCenter.default.addObserver(self,
                            selector: #selector(appCameToForeGround(notification:)),
                            name: UIApplication.willEnterForegroundNotification,
                            object: nil)

    }

    @objc func appCameToForeGround(notification: Notification) {
        self.loadCurrentAccount()
    }
    
    func initMSAL() throws {

            guard let authorityURL = URL(string: kAuthority) else {
                self.updateLogging(text: "Unable to create authority URL")
                return
            }

            let authority = try MSALAADAuthority(url: authorityURL)

            let msalConfiguration = MSALPublicClientApplicationConfig(clientId: kClientID, redirectUri: nil, authority: authority)
            self.applicationContext = try MSALPublicClientApplication(configuration: msalConfiguration)
            self.initWebViewParams()
        }
    
    func initWebViewParams() {
            self.webViewParameters = MSALWebviewParameters(authPresentationViewController: self)
        }
    
    func getGraphEndpoint() -> String {
            return kGraphEndpoint.hasSuffix("/") ? (kGraphEndpoint + "v1.0/me/") : (kGraphEndpoint + "/v1.0/me/");
        }

    @objc func callGraphAPI(_ sender: AnyObject) {

            self.loadCurrentAccount { (account) in

                guard let currentAccount = account else {

                    // We check to see if we have a current logged in account.
                    // If we don't, then we need to sign someone in.
                    self.acquireTokenInteractively()
                    return
                }

                self.acquireTokenSilently(currentAccount)
            }
    }

    typealias AccountCompletion = (MSALAccount?) -> Void

    func loadCurrentAccount(completion: AccountCompletion? = nil) {

            guard let applicationContext = self.applicationContext else { return }

            let msalParameters = MSALParameters()
            msalParameters.completionBlockQueue = DispatchQueue.main

            applicationContext.getCurrentAccount(with: msalParameters, completionBlock: { (currentAccount, previousAccount, error) in

                if let error = error {
                    self.updateLogging(text: "Couldn't query current account with error: \(error)")
                    return
                }

                if let currentAccount = currentAccount {

                    self.updateLogging(text: "Found a signed in account \(String(describing: currentAccount.username)). Updating data for that account...")

                    self.updateCurrentAccount(account: currentAccount)

                    if let completion = completion {
                        completion(self.currentAccount)
                    }

                    return
                }

                self.updateLogging(text: "Account signed out. Updating UX")
                self.accessToken = ""
                self.updateCurrentAccount(account: nil)

                if let completion = completion {
                    completion(nil)
                }
            })
    }
    
    func acquireTokenInteractively() {

        guard let applicationContext = self.applicationContext else { return }
        guard let webViewParameters = self.webViewParameters else { return }

        // #1
        let parameters = MSALInteractiveTokenParameters(scopes: kScopes, webviewParameters: webViewParameters)
        parameters.promptType = .selectAccount

        // #2
        applicationContext.acquireToken(with: parameters) { (result, error) in

            // #3
            if let error = error {

                self.updateLogging(text: "Could not acquire token: \(error)")
                return
            }

            guard let result = result else {

                self.updateLogging(text: "Could not acquire token: No result returned")
                return
            }

            // #4
            self.accessToken = result.accessToken
            self.updateLogging(text: "Access token is \(self.accessToken)")
            self.updateCurrentAccount(account: result.account)
            self.getContentWithToken()
        }
    }
    
    func acquireTokenSilently(_ account : MSALAccount!) {

            guard let applicationContext = self.applicationContext else { return }

            /**

             Acquire a token for an existing account silently

             - forScopes:           Permissions you want included in the access token received
             in the result in the completionBlock. Not all scopes are
             guaranteed to be included in the access token returned.
             - account:             An account object that we retrieved from the application object before that the
             authentication flow will be locked down to.
             - completionBlock:     The completion block that will be called when the authentication
             flow completes, or encounters an error.
             */

            let parameters = MSALSilentTokenParameters(scopes: kScopes, account: account)

            applicationContext.acquireTokenSilent(with: parameters) { (result, error) in

                if let error = error {

                    let nsError = error as NSError

                    // interactionRequired means we need to ask the user to sign-in. This usually happens
                    // when the user's Refresh Token is expired or if the user has changed their password
                    // among other possible reasons.

                    if (nsError.domain == MSALErrorDomain) {

                        if (nsError.code == MSALError.interactionRequired.rawValue) {

                            DispatchQueue.main.async {
                                self.acquireTokenInteractively()
                            }
                            return
                        }
                    }

                    self.updateLogging(text: "Could not acquire token silently: \(error)")
                    return
                }

                guard let result = result else {

                    self.updateLogging(text: "Could not acquire token: No result returned")
                    return
                }

                self.accessToken = result.accessToken
                self.updateLogging(text: "Refreshed Access token is \(self.accessToken)")
                self.updateSignOutButton(enabled: true)
                self.getContentWithToken()
            }
    }
    
    func getContentWithToken() {

            // Specify the Graph API endpoint
            let graphURI = getGraphEndpoint()
            let url = URL(string: graphURI)
            var request = URLRequest(url: url!)

            // Set the Authorization header for the request. We use Bearer tokens, so we specify Bearer + the token we got from the result
            request.setValue("Bearer \(self.accessToken)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, response, error in

                if let error = error {
                    self.updateLogging(text: "Couldn't get graph result: \(error)")
                    return
                }

                guard let result = try? JSONSerialization.jsonObject(with: data!, options: []) else {

                    self.updateLogging(text: "Couldn't deserialize result JSON")
                    return
                }

                self.updateLogging(text: "Result from Graph: \(result))")

                }.resume()
    }
    
    @objc func signOut(_ sender: AnyObject) {

            guard let applicationContext = self.applicationContext else { return }

            guard let account = self.currentAccount else { return }

            do {

                /**
                 Removes all tokens from the cache for this application for the provided account

                 - account:    The account to remove from the cache
                 */

                let signoutParameters = MSALSignoutParameters(webviewParameters: self.webViewParameters!)
                signoutParameters.signoutFromBrowser = false // set this to true if you also want to signout from browser or webview

                applicationContext.signout(with: account, signoutParameters: signoutParameters, completionBlock: {(success, error) in

                    if let error = error {
                        self.updateLogging(text: "Couldn't sign out account with error: \(error)")
                        return
                    }

                    self.updateLogging(text: "Sign out completed successfully")
                    self.accessToken = ""
                    self.updateCurrentAccount(account: nil)
                })

            }
    }
    
    func updateLogging(text : String) {

            if Thread.isMainThread {
                self.loggingText.text = text
            } else {
                DispatchQueue.main.async {
                    self.loggingText.text = text
                }
            }
        }

    func updateSignOutButton(enabled : Bool) {
            if Thread.isMainThread {
                self.signOutButton.isEnabled = enabled
            } else {
                DispatchQueue.main.async {
                    self.signOutButton.isEnabled = enabled
                }
            }
    }

    func updateAccountLabel() {

            guard let currentAccount = self.currentAccount else {
                self.usernameLabel.text = "Signed out"
                return
            }

            self.usernameLabel.text = currentAccount.username
        }

        func updateCurrentAccount(account: MSALAccount?) {
            self.currentAccount = account
            self.updateAccountLabel()
            self.updateSignOutButton(enabled: account != nil)
    }
    
    @objc func getDeviceMode(_ sender: AnyObject) {

            if #available(iOS 13.0, *) {
                self.applicationContext?.getDeviceInformation(with: nil, completionBlock: { (deviceInformation, error) in

                    guard let deviceInfo = deviceInformation else {
                        self.updateLogging(text: "Device info not returned. Error: \(String(describing: error))")
                        return
                    }

                    let isSharedDevice = deviceInfo.deviceMode == .shared
                    let modeString = isSharedDevice ? "shared" : "private"
                    self.updateLogging(text: "Received device info. Device is in the \(modeString) mode.")
                })
            } else {
                self.updateLogging(text: "Running on older iOS. GetDeviceInformation API is unavailable.")
            }
        
        IntuneMAMDiagnosticConsole.display()
    }
    
    @objc func registerEnroll(_ sender: UIButton) {
        guard let applicationContext = self.applicationContext else { return }
        guard let account = self.currentAccount else {
            self.updateLogging(text: "No account found for enrollment, need to login first!")
            return
        }
        
        //Login the user through the Intune sign in flow. EnrollmentDelegateClass will handle the outcome of this.
        let accountIdentifier = account.homeAccountId?.objectId ?? ""
        print("Guid/Account OID:" + (accountIdentifier))
        
        IntuneMAMEnrollmentManager.instance().registerAndEnrollAccountId(accountIdentifier)
        
        
    }
    @objc func UnEnroll(_ sender: UIButton) {
        guard let applicationContext = self.applicationContext else { return }
        guard let account = self.currentAccount else {
            self.updateLogging(text: "No account found for Unenrollment, need to login and enroll first!")
            return
        }
        let accountIdentifier = account.homeAccountId?.objectId ?? ""
        //Login the user through the Intune sign in flow. EnrollmentDelegateClass will handle the outcome of this.
        print("Trigger Unenroll request. User name: " + (accountIdentifier))
        IntuneMAMEnrollmentManager.instance().deRegisterAndUnenrollAccountId((accountIdentifier), withWipe: false)
    }
    
    override func viewDidLoad() {

            super.viewDidLoad()
        
            initUI()

            do {
                try self.initMSAL()
            } catch let error {
                self.updateLogging(text: "Unable to create Application Context \(error)")
            }

            self.loadCurrentAccount()
            self.platformViewDidLoadSetup()
    }

}


