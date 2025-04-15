import { Component } from '@angular/core';
import { NavbarComponent } from './navbar/navbar.component';  // Import NavbarComponent
import { RouterLink, RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss'],
  standalone: true,  // Optional: If using Angular standalone components (Angular 14+)
  imports: [NavbarComponent,RouterOutlet,RouterLink],  // Make sure NavbarComponent is included in imports
})
export class AppComponent {
  title = 'taskz-web';
}