import { Component, OnInit } from '@angular/core';
import { Workspace, WorkspaceService } from '../../core/services/workspace.service';
import { Board, BoardService } from '../../core/services/board.service';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-projects',
  imports: [CommonModule,RouterModule,FormsModule],
  templateUrl: './projects.component.html',
  styleUrl: './projects.component.scss'
})
export class ProjectsComponent implements OnInit {

  workspaces: Workspace[] = [];
    boardsByWorkspace: { [key: number]: Board[] } = {};
  
    constructor(
      private workspaceService: WorkspaceService,
      private boardService: BoardService
    ) {}
  
    showBoardModal: boolean = false;
  newBoardName: string = '';
  selectedWorkspaceId: number | null = null;
  
  openBoardModal(workspaceId: number) {
    this.selectedWorkspaceId = workspaceId;
    this.newBoardName = '';
    this.showBoardModal = true;
  }
  
  closeBoardModal() {
    this.showBoardModal = false;
  }
  
  createNewBoard() {
    if (!this.newBoardName.trim() || this.selectedWorkspaceId === null) return;
  
    this.boardService.createBoard(this.selectedWorkspaceId, this.newBoardName, '#FFFFFF').subscribe(newBoard => {
      if (!this.boardsByWorkspace[this.selectedWorkspaceId!]) {
        this.boardsByWorkspace[this.selectedWorkspaceId!] = [];
      }
      this.boardsByWorkspace[this.selectedWorkspaceId!].push(newBoard);
      this.closeBoardModal();
    });
  }
  
    ngOnInit(): void {
      this.workspaceService.getWorkspaces().subscribe((workspaces) => {
        this.workspaces = workspaces;
  
        this.workspaces.forEach((workspace) => {
          this.boardService.getBoards(workspace.id).subscribe((boards) => {
            this.boardsByWorkspace[workspace.id] = boards;
          });
        });
      });
    }
  

}
