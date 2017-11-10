import RxSwift

extension Observable {
    func subscribeNext(next: ((Element) -> Void)?) -> Disposable {
        return subscribe(onNext: next, onError: nil, onCompleted: nil, onDisposed: nil)
    }
}
