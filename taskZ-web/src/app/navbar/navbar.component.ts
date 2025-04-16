import { CommonModule } from '@angular/common';
import { Component, HostListener, inject, OnInit } from '@angular/core';
import { NavigationEnd, Router, RouterModule } from '@angular/router';
import { ProfileService, UserProfile } from '../services/profile.service';
import { HttpClient, HttpClientModule } from '@angular/common/http';

@Component({
  selector: 'app-navbar',
  imports: [RouterModule, CommonModule, HttpClientModule],
  templateUrl: './navbar.component.html',
  styleUrl: './navbar.component.scss',
  standalone: true
})
export class NavbarComponent implements OnInit {
  showNavbar = true;
  showProfileMenu = false;
  userProfile: UserProfile | null = null;
  
  private router = inject(Router);
  private profileService = inject(ProfileService);

  constructor() {
    this.router.events.subscribe((event: any) => {
      if (event instanceof NavigationEnd) {
        const hiddenRoutes = ['/login', '/register'];
        this.showNavbar = !hiddenRoutes.includes(event.urlAfterRedirects);
      }
    });
  }

  ngOnInit() {
    this.loadProfile();
  }

  loadProfile() {
    this.profileService.getProfile().subscribe({
      next: (profile) => {
        this.userProfile = profile;
      },
      error: (error) => {
        console.error('Error loading profile:', error);
      }
    });
  }

  toggleProfileMenu() {
    this.showProfileMenu = !this.showProfileMenu;
  }

  closeProfileMenu() {
    this.showProfileMenu = false;
  }

  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent) {
    const profileSection = document.querySelector('.profile-section');
    if (profileSection && !profileSection.contains(event.target as Node)) {
      this.closeProfileMenu();
    }
  }

  getInitials(): string {
    if (!this.userProfile) return '';
    const firstInitial = this.userProfile.firstName.charAt(0);
    const lastInitial = this.userProfile.lastName.charAt(0);
    return `${firstInitial}${lastInitial}`.toUpperCase();
  }

  logout() {
    this.profileService.logout().subscribe({
      next: () => {
        this.router.navigate(['/login']);
      },
      error: (error) => {
        console.error('Error during logout:', error);
      }
    });
  }
}
