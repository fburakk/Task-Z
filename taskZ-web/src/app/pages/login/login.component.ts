import { Component, inject } from '@angular/core';
import { Router, RouterLink, RouterOutlet } from '@angular/router';
import { FormsModule } from '@angular/forms';



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

  onLogin(){
    const isLocalData = localStorage.getItem("angular19Local");
    if(isLocalData != null){
      const users = JSON.parse(isLocalData);

      const isUserFound = users.find((m:any)=> m.Email == this.userLogin.Email && m.Password == this.userLogin.Password);
      if(isUserFound != undefined){ 

        localStorage.setItem('loggedInUser', JSON.stringify(isUserFound));
        this.router.navigateByUrl('home')

      }
      else {
        alert("ERROR!")
      }
    }
  }

}
