import { Component, inject } from '@angular/core';
import { Board, BoardService, BoardUser } from '../../core/services/board.service';
import { ActivatedRoute } from '@angular/router';
import { CommonModule } from '@angular/common';
import { Task, TaskService } from '../../core/services/task.service';

@Component({
  selector: 'app-project-detail',
  imports: [CommonModule],
  templateUrl: './project-detail.component.html',
  styleUrl: './project-detail.component.scss'
})
export class ProjectDetailComponent {


  constructor(
    private boardService: BoardService,
    private route: ActivatedRoute,
    private taskService: TaskService
  ) {}

  public board: Board | undefined;
  public boardUsers: BoardUser[] = [];
  public tasks: Task[] = [];



  ngOnInit(): void{
    const boardId = Number(this.route.snapshot.paramMap.get('id'));

    if(boardId){
      this.boardService.getBoard(boardId).subscribe((data)=>{
        this.board=data;
      })
    }


    this.boardService.getBoardUsers(boardId).subscribe((data)=> {
      this.boardUsers = data;
    })

    this.taskService.getBoardTasks(boardId).subscribe((data)=> {
      this.tasks = data;
    })


  }

}