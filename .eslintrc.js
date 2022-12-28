module.exports = {
  env: {
    browser: true,
    commonjs: true,
    es6: true
  },
  extends: 'standard',
  overrides: [
  ],
  parserOptions: {
    ecmaVersion: 6
  },
  ignorePatterns: [
    'app/apps/themes/camaleon_first/assets/js/magnific.min.js',
    'app/apps/themes/camaleon_first/assets/js/modernizr.custom.js',
    'app/assets/javascripts/camaleon_cms/bootstrap.*',
    'app/assets/javascripts/camaleon_cms/admin/_bootstrap*',
    'app/assets/javascripts/camaleon_cms/admin/bootstrap*',
    'app/assets/javascripts/camaleon_cms/admin/introjs/*',
    'app/assets/javascripts/camaleon_cms/admin/_jquery*',
    'app/assets/javascripts/camaleon_cms/admin/jquery*',
    'app/assets/javascripts/camaleon_cms/admin/jquery_validate/*',
    'app/assets/javascripts/camaleon_cms/admin/lte/*',
    'app/assets/javascripts/camaleon_cms/admin/momentjs/*',
    'app/assets/javascripts/camaleon_cms/admin/tageditor/*',
    'app/assets/javascripts/camaleon_cms/admin/tinymce/*',
    'app/assets/javascripts/camaleon_cms/admin/_underscore.js',
    'app/assets/javascripts/camaleon_cms/admin/uploader/_cropper.*',
    'app/assets/javascripts/camaleon_cms/admin/uploader/_jquery.*'
  ],
  rules: {
    'space-before-function-paren': ['error', 'never'],
    curly: ['error', 'multi-or-nest']
  }
}
