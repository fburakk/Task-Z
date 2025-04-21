import { Component, OnInit } from '@angular/core';
import { Workspace, WorkspaceService } from '../../core/services/workspace.service';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-home',
  standalone: true, // Bu özelliği kullanıyorsanız, standalone modülünün olması gerekebilir.
  imports: [CommonModule],  // CommonModule burada doğru şekilde dahil edilmiş
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.scss']  // Burada styleUrls kullanmalısınız
})
export class HomeComponent implements OnInit {

  workspaces: Workspace[] = [];

  constructor(private workspaceService: WorkspaceService) {}

  ngOnInit(): void {
    this.workspaceService.getWorkspaces().subscribe((data) => {
      this.workspaces = data;  // Servisten gelen veriyi workspaces dizisine atıyoruz
    });
  }

}
