import UIKit

final class ProfileViewController: UIViewController {
    
    private let avatarImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "UserAvatar")
        imageView.layer.cornerRadius = 35
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        updateProfileInfo()
        setupObservers()
    }
    
    private func setupUI() {
        
        [avatarImage, nameLabel, emailLabel, descriptionLabel, logoutButton].forEach { view.addSubview($0) }
        
        NSLayoutConstraint.activate([
            avatarImage.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            avatarImage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            avatarImage.widthAnchor.constraint(equalToConstant: 70),
            avatarImage.heightAnchor.constraint(equalToConstant: 70),
            
            nameLabel.topAnchor.constraint(equalTo: avatarImage.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            emailLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            descriptionLabel.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            logoutButton.widthAnchor.constraint(equalToConstant: 24),
            logoutButton.heightAnchor.constraint(equalToConstant: 24),
            logoutButton.centerYAnchor.constraint(equalTo: avatarImage.centerYAnchor),
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
           
           // Если аватарка уже загружена — обновим сразу
           updateAvatar()
       }
       
       // MARK: - Обновление аватарки
       private func updateAvatar() {
           guard let avatarURL = ProfileImageService.shared.avatarURL,
                 let url = URL(string: avatarURL) else { return }
           
           // TODO: В следующем уроке подключим Kingfisher для загрузки изображения
           print("🔄 Загружаем аватарку: \(url)")
       }
       
       // MARK: - Обновление данных профиля
       private func updateProfileInfo() {
           guard let profile = ProfileService.shared.profile else { return }
           
           nameLabel.text = profile.name
           emailLabel.text = profile.loginName
           descriptionLabel.text = profile.bio
       }
    
    @objc private func logoutButtonTapped() {
        // TODO: - Добавить логику при нажатии на кнопку
    }
}
