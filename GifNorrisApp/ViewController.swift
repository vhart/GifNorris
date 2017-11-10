import UIKit
import RxSwift

class ChuckNorrisFactsViewController: UIViewController {

    let disposeBag = DisposeBag()
    let service = ChuckNorrisService()

    override func viewDidLoad() {
        super.viewDidLoad()

        service.pollForText().subscribeNext { text in
            print(text)
        }.addDisposableTo(disposeBag)
    }
}

