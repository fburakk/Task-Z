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
        alert("Registration successful!");
        // this.router.navigateByUrl('/login');
      },
      error: (error: HttpErrorResponse) => {
        console.error("Registration failed:", error);
        console.error("HTTP Status Code:", error.status);
        console.error("Error Message:", error.message);

        if (error.error) {
          console.error("Backend Error:", error.error);
        }

        alert("An error occurred during registration!");
      },
      complete: () => {
        console.log("Registration process completed.");
      }
    });

}
}
