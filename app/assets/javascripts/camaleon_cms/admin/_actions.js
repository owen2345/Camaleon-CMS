/* eslint-env jquery */
jQuery(document).on('ready page:changed', function() {
  // initialize all validations for forms
  InitFormValidations()
  setTimeout(PageActions, 1000)
  if (!$('body').attr('data-intro')) setTimeout(InitIntro, 500)
})

// show admin intro presentation
function InitIntro() {
  const finish = function() {
    $.get(root_admin_url + '/ajax', { mode: 'save_intro' })
    const layer = $('.introjs-overlay').clone()
    const of = $('.introjs-tooltip').offset()
    const c = $('.introjs-tooltip')
      .clone().css($.extend({}, { 'min-width': '0', position: 'absolute', overflow: 'hidden', zIndex: 9999999 }, of))

    $('html, body').animate({ scrollTop: $('body').height() }, 0)
    setTimeout(function() {
      $('body').append(layer, c)
      c.animate(
        $.extend({}, { width: 75, height: 20 }, $('#link_see_intro').offset()),
        'slow',
        function() { setTimeout(function() { c.remove(); layer.remove() }, 500) }
      )
    }, 5)
  }
  introJs().setOptions({
    exitOnEsc: false,
    exitOnOverlayClick: false,
    showStepNumbers: false,
    showBullets: false,
    disableInteraction: true
  }).oncomplete(finish).onexit(finish).onbeforechange(function(ele) {
    if ($(ele).hasClass('treeview') && !$(ele).hasClass('active'))
      $(ele).children('a').click()

    if ($(ele).is('li')) {
      const tree = $(ele).closest('ul')

      if (!tree.hasClass('menu-open')) tree.prev('a').click()
    }
  }).start()
}

// basic and common actions
const PageActions = () => {
  // button actions
  $('#admin_content a[role="back"]').on('click', () => { window.history.back(); return false })
  $('a[data-toggle="tooltip"], button[data-toggle="tooltip"], a[title!=""]', '#admin_content').not('.skip_tooltip').tooltip()

  /* PANELS */
  $('#admin_content').on('click',
    '.panel .panel-collapse',
    function() {
      PanelCollapse($(this).parents('.panel:first'))
      $(this).parents('.dropdown').removeClass('open')
      return false
    })
}

// add action to toggle the collapse for panels
function PanelCollapse(panel, action, callback) {
  if (panel.hasClass('panel-toggled')) {
    panel.removeClass('panel-toggled')
    panel.find('.panel-collapse .fa-angle-up').removeClass('fa-angle-up').addClass('fa-angle-down')
    if (action && action === 'shown' && typeof callback === 'function')
      callback()
  } else {
    panel.addClass('panel-toggled')
    panel.find('.panel-collapse .fa-angle-down').removeClass('fa-angle-down').addClass('fa-angle-up')
    if (action && action === 'hidden' && typeof callback === 'function')
      callback()
  }
}

/* PLAY SOUND FUNCTION */
// eslint-disable-next-line no-unused-vars
function playAudio(file) {
  if (file === 'alert')
    document.getElementById('audio-alert').play()

  if (file === 'fail')
    document.getElementById('audio-fail').play()
}

/* NEW OBJECT(GET SIZE OF ARRAY) */
Object.size = function(obj) {
  let size = 0
  let key

  for (key in obj) {
    if (Object.prototype.hasOwnProperty.call(obj, key))
      size++
  }

  return size
}

// this is a fix for multiples modals when a modal was closed (reactivate scroll for next modal)
// fix for boostrap multiple modals problem
// eslint-disable-next-line no-unused-vars
function ModalFixMultiple() {
  const activeModal = $('.modal.in:last', 'body').data('bs.modal')

  if (activeModal) {
    activeModal.$body.addClass('modal-open')
    activeModal.enforceFocus()
    activeModal.handleUpdate()
  }
}
