import { Component, inject } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../core/services/auth.service';
import { HttpErrorResponse } from '@angular/common/http';


@Component({
  selector: 'app-register',
  imports: [FormsModule,RouterLink],
  templateUrl: './register.component.html',
  styleUrl: './register.component.scss'
})
export class RegisterComponent {

  userRegisterObj: any = {
    username: '',
    email: '',
    password: '',
    firstName: '',
    lastName: ''
  };
  
  
  router = inject(Router);
  authService = inject(AuthService);

  onRegister(){
    this.authService.register(this.userRegisterObj).subscribe({
      next: (response) => {
        // Kayıt başarılı olduysa
        alert("Kayıt başarılı!");
        // this.router.navigateByUrl('/login');
      },
      error: (error: HttpErrorResponse) => {
        // Hata durumunda daha fazla bilgi alıyoruz
        console.error("Kayıt işlemi başarısız:", error);
  
        // HTTP hata kodu
        console.error("Hata Kodu:", error.status);
  
        // HTTP hata mesajı
        console.error("Hata Mesajı:", error.message);
  
        // Geri dönen hata verisi (Backend'in döndürdüğü detaylı mesajlar)
        if (error.error) {
          console.error("Backend Hata Mesajı:", error.error);
        }
  
        alert("Kayıt sırasında bir hata oluştu!");
      },
      complete: () => {
        console.log("Register işlemi tamamlandı.");
      }
    });

}
}
