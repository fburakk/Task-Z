import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { PLATFORM_ID } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

export const authGuard: CanActivateFn = (route, state) => {
  const router = inject(Router);
  const platformId = inject(PLATFORM_ID);

  // During SSR, always allow navigation (the page will be re-checked in the browser)
  if (!isPlatformBrowser(platformId)) {
    return true;
  }

  const token = localStorage.getItem('jwtToken');
  if (token) {
    return true;
  } else {
    router.navigateByUrl('login');
    return false;
  }
};
