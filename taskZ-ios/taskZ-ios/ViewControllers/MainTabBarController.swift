import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
    }
    
    private func setupTabs() {
        let boardsVC = BoardsViewController()
        let boardsNav = UINavigationController(rootViewController: boardsVC)
        boardsNav.tabBarItem = UITabBarItem(title: "Panolar", image: UIImage(systemName: "mail.stack"), tag: 0)
        
        let cardsVC = MyCardsViewController() // Placeholder for cards screen
        cardsVC.view.backgroundColor = .black
        cardsVC.title = "Kartlarım"
        let cardsNav = UINavigationController(rootViewController: cardsVC)
        cardsNav.tabBarItem = UITabBarItem(title: "Kartlarım", image: UIImage(systemName: "list.bullet.below.rectangle"), tag: 1)
        
        let profileVC = ProfileViewController()
        let profileNav = UINavigationController(rootViewController: profileVC)
        profileNav.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person"), tag: 2)
        
        viewControllers = [boardsNav, cardsNav, profileNav]
        selectedIndex = 0
    }
    
    private func setupAppearance() {
        tabBar.tintColor = .cyan
        tabBar.unselectedItemTintColor = .gray
        tabBar.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
            
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        }
    }
} 
