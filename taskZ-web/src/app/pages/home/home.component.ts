import { Component, OnInit } from '@angular/core';
import { Workspace, WorkspaceService } from '../../core/services/workspace.service';
import { CommonModule } from '@angular/common';
import { Board, BoardService } from '../../core/services/board.service';
import { RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule,RouterModule,FormsModule],
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

  showModal: boolean = false;
newBoardName: string = '';
selectedWorkspaceId: number | null = null;

openModal(workspaceId: number) {
  this.selectedWorkspaceId = workspaceId;
  this.newBoardName = '';
  this.showModal = true;
}

closeModal() {
  this.showModal = false;
}

createBoard() {
  if (!this.newBoardName.trim() || this.selectedWorkspaceId === null) return;

  this.boardService.createBoard(this.selectedWorkspaceId, this.newBoardName, '#FFFFFF').subscribe(newBoard => {
    if (!this.boardsByWorkspace[this.selectedWorkspaceId!]) {
      this.boardsByWorkspace[this.selectedWorkspaceId!] = [];
    }
    this.boardsByWorkspace[this.selectedWorkspaceId!].push(newBoard);
    this.closeModal();
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
