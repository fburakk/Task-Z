import { CommonModule } from '@angular/common';
import { Component, HostListener, inject, OnInit } from '@angular/core';
import { NavigationEnd, Router, RouterModule } from '@angular/router';
import { ProfileService, UserProfile } from '../core/services/profile.service';
import { HttpClient, HttpClientModule, HttpErrorResponse } from '@angular/common/http';
import { AuthService } from '../core/services/auth.service';
import { WorkspaceService } from '../core/services/workspace.service';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-navbar',
  imports: [RouterModule, CommonModule, HttpClientModule,FormsModule],
  templateUrl: './navbar.component.html',
  styleUrl: './navbar.component.scss',
  standalone: true
})
export class NavbarComponent implements OnInit {
  showNavbar = true;
  showProfileMenu = false;
  userProfile: UserProfile | null = null;
  isLoggedIn = false;
  
  private router = inject(Router);
  private profileService = inject(ProfileService);
  private authService = inject(AuthService);
  private workSpaceService = inject(WorkspaceService);

  

  constructor() {
    this.router.events.subscribe((event: any) => {
      if (event instanceof NavigationEnd) {
        const hiddenRoutes = ['/login', '/register'];
        this.showNavbar = !hiddenRoutes.includes(event.urlAfterRedirects);

        this.showButton = event.urlAfterRedirects.includes('/projects');
        
        // Check login status and load profile when route changes
        if (!hiddenRoutes.includes(event.urlAfterRedirects)) {
          this.checkLoginAndLoadProfile();
        }
      }
    });
  }

  showWorkSpaceModal: boolean = false;
  newWorkSpaceName: string = '';


  showButton:boolean = false;



  openWorkSpaceModal(){
    this.showWorkSpaceModal = true;
    this.newWorkSpaceName = '';
  }

  closeWorkSpaceModal(){
    this.showWorkSpaceModal = false;
  }

  createWorkSpace(){
    if (!this.newWorkSpaceName.trim()) return;

    this.workSpaceService.createWorkspace(this.newWorkSpaceName).subscribe({
      next: (newWorkSpace) => {

        console.log('Yeni workspace oluşturuldu:', newWorkSpace);
        
        this.closeWorkSpaceModal();
        
        this.newWorkSpaceName = '';},
      error: (error) => {
        console.error('Workspace oluşturulurken hata oluştu:', error);
      }
    });

  }



  ngOnInit() {


    this.checkLoginAndLoadProfile();
  }

  private checkLoginAndLoadProfile() {
    this.isLoggedIn = this.authService.isLoggedIn();
    this.showProfileMenu = false;
    if (this.isLoggedIn) {
      this.loadProfile();
    } else {
      this.userProfile = null;
    }
  }

  loadProfile() {
    this.profileService.getProfile().subscribe({
      next: (profile) => {
        this.userProfile = profile;
      },
      error: (error: HttpErrorResponse) => {
        console.error('Error loading profile:', error);
        if (error.status === 401) {
          // If unauthorized, clear profile and redirect to login
          this.userProfile = null;
          this.isLoggedIn = false;
          this.authService.clearTokens();
          this.router.navigate(['/login']);
        }
      }
    });
  }

  toggleProfileMenu() {
    if (!this.isLoggedIn) return;
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
    this.showProfileMenu = false;
    this.authService.logout().subscribe({
      next: () => {
        this.authService.clearTokens();
        this.isLoggedIn = false;
        this.userProfile = null;
        this.router.navigate(['/login']);
      },
      error: (error) => {
        console.error('Error during logout:', error);
        // Even if the server logout fails, clear local state
        this.authService.clearTokens();
        this.isLoggedIn = false;
        this.userProfile = null;
        this.router.navigate(['/login']);
      }
    });
  }
}
