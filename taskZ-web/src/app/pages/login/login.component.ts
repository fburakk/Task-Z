import { Component, inject } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-login',
  imports: [FormsModule, RouterLink],
  templateUrl: './login.component.html',
  styleUrl: './login.component.scss',
  standalone: true
})
export class LoginComponent {
  userLogin: any = {
    Email: '',
    Password: ''
  };

  router = inject(Router);
  authService = inject(AuthService);

  onLogin() {
    this.authService.login(this.userLogin).subscribe({
      next: (response) => {
        if (response?.token && response?.refreshToken) {
          this.authService.storeTokens(response.token, response.refreshToken);
          this.router.navigate(['/home']);
        } else {
          console.error('Invalid response format:', response);
          alert('Login failed: Invalid server response');
        }
      },
      error: (error) => {
        console.error('Login failed:', error);
        alert('Login failed! Please check your credentials.');
      }
    });
  }
}
