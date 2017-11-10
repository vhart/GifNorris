import Foundation
import RxSwift

protocol RandomTextGenerator {
    func pollForText() -> Observable<String>
}

class ChuckNorrisService: RandomTextGenerator {
    private var disposeBag = DisposeBag()

    enum RequestError: Error {
        case redirection
        case clientError
        case serverError
        case genericError

        init?(code: Int?) {
            guard let code = code else { return nil }

            switch code {
            case 0   ... 299: return nil
            case 300 ... 399: self = .redirection
            case 400 ... 499: self = .clientError
            case 500 ... 599: self = .serverError
            default: self = .genericError
            }
        }
    }

    func pollForText() -> Observable<String> {
        return pollForJokes()
    }

    private func pollForJokes() -> Observable<String> {
        let subject = PublishSubject<String>()
        let scheduler = SerialDispatchQueueScheduler(internalSerialQueueName: "com.gifnorrisapp.chucknorrisservice.polling")

        func pollRandomFacts() {
            getJoke(type: .random)
                .delay(15.0, scheduler: scheduler)
                .subscribe(onNext: { text in
                    subject.onNext(text)
                    pollRandomFacts()
                }, onError: { error in
                    subject.onError(error)
                }, onCompleted: nil, onDisposed: nil)
                .addDisposableTo(disposeBag)
        }

        pollRandomFacts()

        return subject.asObservable()
    }


    func getJoke(type: Endpoint) -> Observable<String> {
        return Observable<String>.create({ observer -> Disposable in
            let task = URLSession.shared
                .dataTask(with: type.url, completionHandler: { data, response, _ in
                    let code = (response as? HTTPURLResponse)?.statusCode
                    if let error = RequestError(code: code) {
                        observer.onError(error)
                        return
                    }

                    guard let data = data, let text = String(data: data, encoding: .utf8) else {
                        observer.onError(RequestError.genericError)
                        return
                    }

                    observer.onNext(text)
                    observer.onCompleted()
            })

            task.resume()
            return Disposables.create()
        })
    }
}

extension ChuckNorrisService {
    struct Parameters {
        static let host = "https://matchilling-chuck-norris-jokes-v1.p.mashape.com"
        static let path = "/jokes"
        static let token = "fXzpSWHlShmshm2D1h8ts3UvoZGbp1OmS0fjsnaifuPHsgIDPb"
        static let headerKeyName = "X-Mashape-Key"
    }

    enum Endpoint: String {
        case science = "/random?category=science"
        case food = "/random?category=food"
        case random = "/random"

        var url: URLRequest {
            let urlString = Parameters.host + Parameters.path + self.rawValue
            let url = URL(string: urlString)!
            var urlRequest = URLRequest(url: url)
            urlRequest.addValue(Parameters.token, forHTTPHeaderField: Parameters.headerKeyName)
            urlRequest.addValue("text/plain", forHTTPHeaderField: "Accept")

            return urlRequest
        }
    }
}
