import { Routes } from '@angular/router';
import { RegisterComponent } from './pages/register/register.component';
import { HomeComponent } from './pages/home/home.component';
import { LoginComponent } from './pages/login/login.component';
import { authGuard } from './auth.guard';
import { ProjectsComponent } from './pages/projects/projects.component';
import { ProjectDetailComponent } from './pages/project-detail/project-detail.component';
import { MyCardsComponent } from './pages/my-cards/my-cards.component';

export const routes: Routes = [
    {
        path:'',
        redirectTo: 'login',
        pathMatch: 'full'
    },
    {
        path:'register',
        component:RegisterComponent
    },
    {
        path:'home',
        component:HomeComponent,
        canActivate: [authGuard]
    },
    {
        path:'login',
        component:LoginComponent
    },
    {
        path:'projects',
        component:ProjectsComponent,
        canActivate: [authGuard]
    },
    {
        path:'project/:id',
        component:ProjectDetailComponent,
        canActivate: [authGuard]
    },
    {
        path:'myCards',
        component: MyCardsComponent,
        canActivate: [authGuard]
    }

];
