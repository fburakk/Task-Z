import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';


@Component({
  selector: 'app-register',
  imports: [FormsModule,RouterLink],
  templateUrl: './register.component.html',
  styleUrl: './register.component.scss'
})
export class RegisterComponent {

  userRegisterObj: any = {
    Name:'',
    Surname:'',
    Username:'',
    Email:'',
    Password:''
  }

  onRegister(){
    const isLocalData = localStorage.getItem("angular19Local");
    if(isLocalData != null){
      const localArray = JSON.parse(isLocalData);
      localArray.push(this.userRegisterObj);
      localStorage.setItem("angular19Local",JSON.stringify(localArray));
    }
    else {
      const localArray = [];
      localArray.push(this.userRegisterObj);
      localStorage.setItem("angular19Local",JSON.stringify(localArray));

    }
    alert("Registerated!");
  }

}
