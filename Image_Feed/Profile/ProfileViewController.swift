import UIKit
import Kingfisher

final class ProfileViewController: UIViewController {
    
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
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.text = "@ekaterina_nov"
        label.textColor = UIColor(named: "YP Grey")
        label.font = .systemFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Hello, world!"
        label.textColor = UIColor(named: "YP White")
        label.font = .systemFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false
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
    private var profileImageObserver: NSObjectProtocol?
    private let profileImageService = ProfileImageService.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP Black")
        setupUI()
        updateProfileInfo()
        setupObservers()
        loadAvatar()
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
    
    // MARK: - Подписка на обновление аватарки
    private func setupObservers() {
        profileImageObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAvatar()
        }
    }
    
    // MARK: - Обновление аватарки
    private func updateAvatar() {
        if let image = ProfileImageService.shared.avatarImage {
            avatarImageView.image = image
            print("🔄 [ProfileViewController.updateAvatar] Аватарка обновлена из сервиса")
        } else {
            print("⚠️ [ProfileViewController.updateAvatar] Аватарка не найдена в сервисе")
            
            guard let avatarURLString = ProfileImageService.shared.avatarURL, !avatarURLString.isEmpty else {
                print("❌ [ProfileViewController.updateAvatar] Ошибка: avatarURL отсутствует или пустое значение")
                avatarImageView.image = UIImage(named: "UserPhoto")
                return
            }
            
            guard let url = URL(string: avatarURLString) else {
                print("❌ [ProfileViewController.updateAvatar] Ошибка: Некорректный URL: \(avatarURLString)")
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
                ]) { result in
                    switch result {
                    case .success(let value):
                        print("✅ [ProfileViewController.updateAvatar] Аватарка успешно загружена: \(value.source.url?.absoluteString ?? "неизвестно")")
                    case .failure(let error):
                        print("❌ [ProfileViewController.updateAvatar] Ошибка загрузки: \(error.localizedDescription)")
                        self.avatarImageView.image = UIImage(named: "UserPhoto")
                    }
                }
        }
    }
    
    // MARK: - Загрузка аватарки
    private func loadAvatar() {
        guard let profile = ProfileService.shared.profile else { return }
        let username = profile.username
        print("✅ [ProfileViewController.loadAvatar] Username: \(username)")
        
        profileImageService.fetchProfileImageURL(username: username) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let image):
                self.avatarImageView.image = image
                print("✅ [ProfileViewController.loadAvatar] Аватарка установлена")
            case .failure(let error):
                print("❌ [ProfileViewController.loadAvatar] Ошибка: \(error.localizedDescription)")
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
    
    @objc private func logoutButtonTapped() {
        showLogoutAler()
    }
    
    private func showLogoutAler() {
        let alert = UIAlertController(title: "Пока, пока!", message: "Уверены, что хотите выйти?", preferredStyle: .alert)
        
        let noAction = UIAlertAction(title: "Нет", style: .default)
        
        let yesAction = UIAlertAction(title: "Да", style: .cancel) { _ in
            ProfileLogoutService.shared.logout()
            UIApplication.shared.windows.first?.rootViewController = SplashViewController()
        }
        
        alert.addAction(noAction)
        alert.addAction(yesAction)
        
        present(alert, animated: true)
    }
}
