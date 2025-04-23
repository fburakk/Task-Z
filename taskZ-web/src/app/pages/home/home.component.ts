import { Component, OnInit } from '@angular/core';
import { Workspace, WorkspaceService } from '../../core/services/workspace.service';
import { CommonModule } from '@angular/common';
import { Board, BoardService } from '../../core/services/board.service';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule,RouterModule],
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.scss']
})
export class HomeComponent implements OnInit {

  workspaces: Workspace[] = [];
  boardsByWorkspace: { [key: number]: Board[] } = {};

  constructor(
    private workspaceService: WorkspaceService,
    private boardService: BoardService
  ) {}

  ngOnInit(): void {
    this.workspaceService.getWorkspaces().subscribe((workspaces) => {
      this.workspaces = workspaces;

      // Her workspace için boardları çek
      this.workspaces.forEach((workspace) => {
        this.boardService.getBoards(workspace.id).subscribe((boards) => {
          this.boardsByWorkspace[workspace.id] = boards;
        });
      });
    });
  }


}
