
export default {
  bootstrap: () => import('./main.server.mjs').then(m => m.default),
  inlineCriticalCss: true,
  baseHref: '/',
  locale: undefined,
  routes: undefined,
  entryPointToBrowserMapping: {},
  assets: {
    'index.csr.html': {size: 4996, hash: '8926b5b2bf69bd4fce5375bc9d0307d7a1ca7188e62e519fecc8cbbef3adc249', text: () => import('./assets-chunks/index_csr_html.mjs').then(m => m.default)},
    'index.server.html': {size: 1112, hash: '59f66981c978d798c3dd393e56aef9071462c6ef38cb6291e9d598d32823e8d9', text: () => import('./assets-chunks/index_server_html.mjs').then(m => m.default)},
    'styles-HFCFGWKV.css': {size: 231660, hash: 'HPxm/5CThws', text: () => import('./assets-chunks/styles-HFCFGWKV_css.mjs').then(m => m.default)}
  },
};
