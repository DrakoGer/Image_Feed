import UIKit
import Kingfisher

final class ProfileViewController: UIViewController, ProfileViewControllerProtocol {
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "UserAvatar")
        imageView.layer.cornerRadius = 35
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.kf.indicatorType = .activity
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Екатерина Новикова"
        label.textColor = UIColor(named: "YP White")
        label.font = .boldSystemFont(ofSize: 23)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "nameLabel"
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.text = "@ekaterina_nov"
        label.textColor = UIColor(named: "YP Grey")
        label.font = .systemFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "emailLabel"
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Hello, world!"
        label.textColor = UIColor(named: "YP White")
        label.font = .systemFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "descriptionLabel"
        return label
    }()
    
    private lazy var logoutButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Logout"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Подписка на изменения аватарки
    var presenter: ProfilePresenterProtocol?
    
    init(presenter: ProfilePresenterProtocol? = ProfilePresenter()) {
            self.presenter = presenter
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            self.presenter = ProfilePresenter()
        }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                view.backgroundColor = UIColor(named: "YP Black")
                setupUI()
                presenter?.view = self
                presenter?.viewDidLoad()
    }
    
    private func setupUI() {
        [avatarImageView, nameLabel, emailLabel, descriptionLabel, logoutButton].forEach { view.addSubview($0) }
        
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            avatarImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: 70),
            avatarImageView.heightAnchor.constraint(equalToConstant: 70),
            
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            emailLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            descriptionLabel.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            logoutButton.widthAnchor.constraint(equalToConstant: 24),
            logoutButton.heightAnchor.constraint(equalToConstant: 24),
            logoutButton.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
    }
    
    
    func updateProfileDetails(name: String, login: String, description: String?) {
            nameLabel.text = name
            emailLabel.text = login
            descriptionLabel.text = description
        }
    

    func updateAvatar(url: URL?) {
            guard let url = url else {
                avatarImageView.image = UIImage(named: "UserPhoto")
                return
            }
            let processor = RoundCornerImageProcessor(cornerRadius: 50, backgroundColor: .ypBlack)
            avatarImageView.kf.setImage(
                with: url,
                placeholder: UIImage(named: "UserPhoto"),
                options: [
                    .processor(processor),
                    .transition(.fade(0.3))
                ]
            ) { result in
                switch result {
                case .success:
                    print("✅ [ProfileViewController.updateAvatar] Аватарка успешно загружена")
                case .failure(let error):
                    print("❌ [ProfileViewController.updateAvatar] Ошибка загрузки: \(error.localizedDescription)")
                    self.avatarImageView.image = UIImage(named: "UserPhoto")
                }
            }
        }
    
    // MARK: - Обновление данных профиля
    private func updateProfileInfo() {
        guard let profile = ProfileService.shared.profile else { return }
        print("🔍 [ProfileViewController.updateProfileInfo] Профиль: username=\(profile.username), name=\(profile.name), loginName=\(profile.loginName)")
        nameLabel.text = profile.name
        emailLabel.text = profile.loginName
        descriptionLabel.text = profile.bio
    }
    
    @objc func logoutButtonTapped() {
            presenter?.didTapLogoutButton()
        }
    
    func showLogoutAlert(completion: @escaping () -> Void) {
        let alert = UIAlertController(title: "Пока, пока!", message: "Уверены, что хотите выйти?", preferredStyle: .alert)
        let noAction = UIAlertAction(title: "Нет", style: .default)
        let yesAction = UIAlertAction(title: "Да", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true) {
                completion()
            }
        }
        alert.addAction(noAction)
        alert.addAction(yesAction)
        present(alert, animated: true)
        }
}
