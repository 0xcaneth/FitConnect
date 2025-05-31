// Services/AuthService.swift
import Foundation
import FirebaseAuth

struct AuthService {

  // MARK: - Kullanıcı Kayıt (Sign Up)
  static func signUp(
    email: String,
    password: String,
    completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void
  ) {
    Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
      if let error = error {
        completion(.failure(error))
        return
      }
      guard let firebaseUser = authResult?.user else {
        let nsError = NSError(
          domain: "AuthService",
          code: -1,
          userInfo: [NSLocalizedDescriptionKey: "Bilinmeyen kayıt hatası"]
        )
        completion(.failure(nsError))
        return
      }

      firebaseUser.sendEmailVerification { sendError in
        if let sendError = sendError {
          completion(.failure(sendError))
        } else {
          completion(.success(firebaseUser))
        }
      }
    }
  }

  // MARK: - Giriş Yapma (Log In)
  static func login(
    email: String,
    password: String,
    completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void
  ) {
    Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
      if let error = error {
        completion(.failure(error)); return
      }
      guard let firebaseUser = authResult?.user else {
        let nsError = NSError(
          domain: "AuthService",
          code: -1,
          userInfo: [NSLocalizedDescriptionKey: "Bilinmeyen giriş hatası"]
        )
        completion(.failure(nsError)); return
      }
      completion(.success(firebaseUser))
    }
  }

  // MARK: - Şifre Sıfırlama (Password Reset)
  static func resetPassword(
    email: String,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    Auth.auth().sendPasswordReset(withEmail: email) { error in
      if let error = error { completion(.failure(error)) }
      else                  { completion(.success(()))  }
    }
  }

  // MARK: - E-posta Doğrulama Kodu Kontrolü (Action Code)
  static func applyVerificationCode(
    _ code: String,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    Auth.auth().applyActionCode(code) { error in
      if let error = error { completion(.failure(error)) }
      else                  { completion(.success(()))  }
    }
  }

}
