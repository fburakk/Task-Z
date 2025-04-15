import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';

export const authGuard: CanActivateFn = (route, state) => {
  const router = inject(Router);
  const user = localStorage.getItem('loggedInUser');

if(user){
  return true;
}
else {
  router.navigateByUrl('login');
  return false;
}

};
