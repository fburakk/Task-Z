import { Component } from '@angular/core';

interface WorkspaceCard {
  title: string;
  color?: string;
}

@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.scss']
})
export class HomeComponent {
  workspaceName = 'BK Mobile';
  cards: WorkspaceCard[] = [
    { title: 'AkdenizApp', color: '#E67E22' },
    { title: 'Api', color: '#3498DB' },
    { title: 'AppSpy', color: '#2E86C1' },
    { title: 'LinkManager', color: '#34495E' }
  ];
  remainingCards = 6;
} 