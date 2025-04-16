import { Component, inject } from '@angular/core';
import { Router, RouterLink, RouterOutlet } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../core/services/auth.service';



@Component({
  selector: 'app-login',
  imports: [FormsModule,RouterLink],
  templateUrl: './login.component.html',
  styleUrl: './login.component.scss'
})
export class LoginComponent {

  userLogin: any = {
    Email:'',
    Password:''
  }

  router = inject(Router);
  authService = inject(AuthService);

  onLogin(){
    this.authService.login(this.userLogin).subscribe({
      next: (response) => {
        // Backend'den gelen cevap, JWT token ve refresh token'ı localStorage'a kaydediyoruz
        if (response?.token && response?.refreshToken) {
          this.authService.storeTokens(response.token, response.refreshToken);
          
          // Başarılı giriş sonrası kullanıcıyı ana sayfaya yönlendiriyoruz
          this.router.navigateByUrl('home');
        } else {
          alert("Error! Could not get token.");
        }
      },
      error: (error) => {
        // Hata durumu
        console.error("Log in failed:", error);
        alert("Giriş başarısız! Lütfen bilgilerinizi kontrol edin.");
      },
      complete: () => {
        console.log("Login attempt complete");
      }
    });
  }

}
