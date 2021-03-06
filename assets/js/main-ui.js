(function ($) {
  $(document).ready(function () {
    var $signInBtn = $('#sign-in-btn'),
        $auth = $('.auth-dropdown'),
        $best = $('.best-dropdown'),
        $hamburger = $('.hamburger'),
        $navItems = $('.nav-items'),
        $overlay = $('.overlay'),

        r = window.remodals = {};

    function convertTime () {
      $.each($('.t_time'), function(index, val) {
         var time = $(val).text().split(',');

         $(val).text(time.join(':'));
      });
    }

    convertTime();
    window.convertTime = convertTime;

    window.restime = "";

    window.socialinit = function() {
      //var urlFb = 'https://www.facebook.com/sharer/sharer.php?u=https://sudoku-spielen.org&display=popup&title=Sudoku spielen&description=Я решил судоку за ' + window.restime + ' на ' + window.level + ' уровне сложности.';
      //var urlTw = 'https://twitter.com/intent/tweet?url=https://sudoku-spielen.org&text=Я решил судоку за ' + window.restime + ' на ' + window.level + ' уровне сложности.';
      //var urlGp = 'https://plus.google.com/share?url=https://sudoku-spielen.org'      
      var urlFb = 'https://www.facebook.com/sharer/sharer.php?u=https://sudoku-spielen.org&display=popup&title=Sudoku spielen&description=Ich spiele Sudoku. Mein Ergebnis ist: ' + $('.res-time').html() + '. Schwierigkeitsgrad: ' + window.level  + '. Kannst Du es besser machen? Versuche es mal: https://sudoku-spielen.org/';
      var urlTw = 'https://twitter.com/intent/tweet?url=https://sudoku-spielen.org&amp;text=Ich spiele Sudoku. Mein Ergebnis ist: ' + $('.res-time').html() + '. Schwierigkeitsgrad: ' + window.level + '. Kannst Du es besser machen?';
      var urlGp = 'https://plus.google.com/share?url=https://sudoku-spielen.org'
      
      $('#shareLinkFb').attr('href', urlFb);
      $('#shareLinkTw').attr('href', urlTw);
      $('#shareLinkGp').attr('href', urlGp);
      // $(".modal-social-icons").jsSocials({
      //   showLabel: false,
      //   shareIn: "popup",
      //   showCount: false,
      //   shares: [{
      //     share: "facebook",
      //     logo: "../img/icon-facebook.png"
      //   },
      //   {
      //     share: "googleplus",
      //     logo: "../img/icon-google.png"
      //   }, {
      //     share: "twitter",
      //     logo: "../img/icon-twitter.png"
      //   }]
      // });
    };

    window.socialinit();


    ///////////////////
    // Init Remodals //
    ///////////////////
    r.remodalWrong = $('[data-remodal-id="modal-solution-wrong"]').remodal();
    r.remodalCorrect = $('[data-remodal-id="modal-solution-correct"]').remodal();
    r.remodalCorrectWithoutScores = $('[data-remodal-id="modal-solution-correct-without-scores"]').remodal();
    r.remodalSaves = $('[data-remodal-id="modal-saves"]').remodal();
    r.remodalSend = $('[data-remodal-id="modal-send"]').remodal();
    r.remodalRestore = $('[data-remodal-id="modal-restore"]').remodal();
    r.remodalRestoreFail = $('[data-remodal-id="modal-restore-fail"]').remodal();
    r.remodalValidate = $('[data-remodal-id="modal-validate"]').remodal();

    window.deleteSave = function (e) {
      var stashID = $(this).data('stash-id');
      var $deleteBtn = $(this);

      if (stashID) {
        $.post('/game/delete', { stash_id: stashID}, function(data, textStatus, xhr) {
          if (data.id) {
            $deleteBtn.parent().parent().remove();
            $('.spacer[data-spacer-id="' + stashID + '"]').remove();
            tenStashLimit();
          }
        });
      }
    };

    $('.delete-save').on('click', deleteSave);


    //////////////////////////////////////////////////////////
    // Inform user if he entered existing email or username //
    //////////////////////////////////////////////////////////
    function asyncCheckCredentials(name, $err, value, $this) {
      $.post('/check_' + name, { param: value }, function(data) {
        if (data.status == 'EXIST') {
          $err.show();
          $this.addClass('error');
          $('#signup-btn').prop('disabled', true).addClass('disabled');
        } else {
          $err.hide();
          $this.removeClass('error');
          $('#signup-btn').prop('disabled', false).removeClass('disabled');
        }
      });
    }

    $('#c-register-email').change(function(e) {
      var $this = $(this),
          $err = $('#error-register-email'),
          value = $(this).val();

      setTimeout(function() {
        asyncCheckCredentials('email', $err, value, $this);
      }, 500);
    });

    $('#c-register-name').change(function(e) {
      var $this = $(this),
          $err = $('#error-register-name'),
          value = $(this).val();

      setTimeout(function() {
        asyncCheckCredentials('name', $err, value, $this);
      }, 500);
    })


    //////////////////////////////////////////////////////////
    // Close mobile Main menu when clicked on another place //
    //////////////////////////////////////////////////////////
    $(document).on('click', function (e) {

      if ($(e.target).hasClass('overlay')) {
        $hamburger.removeClass('opened');
        $navItems.hide();
        $overlay.hide();
      }

      // if (!$(e.arget).hasClass('nav-auth') && !$(e.arget).hasClass('auth-dropdown'))
      //   if ($auth.hasClass('opened'))
      //     $auth
      //       .removeClass('opened')
      //       .hide();

      if (!$(e.target).hasClass('nav-best'))
        if ($best.hasClass('opened'))
          $best
            .removeClass('opened')
            .hide();
    });


    ////////////////////////
    // Feedback form send //
    ////////////////////////
    $('#c-form-send').on('click', function (e) {
      var cEmail = $('#c-form-email').val(),
          cUsername = $('#c-form-name').val(),
          cMessage = $('#c-form-message').val();

      if (cEmail && cUsername && cMessage)
        $.post('/send', {
          email: cEmail,
          username: cUsername,
          message: cMessage
        }, function(data, textStatus, xhr) {
          if (textStatus == 'success')
            remodals.remodalSend.open();
        });
      else
        remodals.remodalValidate.open();
    });


    //////////////////////
    // Restore password //
    //////////////////////
    $('#send-password-btn').on('click', function(e) {
      var cResendEmail = $('#c-resend-email').val();

      if (cResendEmail) {
        $.post('/restore', {
          email: cResendEmail
        }, function(data) {
          $('#c-resend-email').val('');
          if (data.status == 'OK') {
            remodals.remodalRestore.open();
          } else {
            remodals.remodalRestoreFail.open();
          }
        });
      }
    });


    ///////////////////////////
    // Toggle hamburger menu //
    ///////////////////////////
    var toggleHamburger = function (e) {
      if ($hamburger.hasClass('opened')) {
        $hamburger.removeClass('opened');
        $navItems.hide();
        $('.overlay').hide()
      } else {
        $hamburger.addClass('opened');
        $navItems.show();
        $('.overlay').show()
      }
    };


    ////////////////////////////////////////
    // Toogle authorization dropdown menu //
    ////////////////////////////////////////
    var toggleAuthMenuItem = function (e) {
      if ($(e.currentTarget).hasClass('nav-auth'))
        if ($auth.hasClass('opened'))
          $auth
            .removeClass('opened')
            .hide();
        else
          $auth
            .addClass('opened')
            .show();
      else
        return false;
    };


    ////////////////////////////////////////
    // Toogle Best players dropdown menu  //
    ////////////////////////////////////////
    var toggleBestPlayers = function (e) {
      if ($best.hasClass('opened'))
          $best
            .removeClass('opened')
            .hide();
        else
          $best
            .addClass('opened')
            .show();
    }


    ////////////////////////////////////////////////
    // Toggle "Lost password" and "Registration"  //
    ////////////////////////////////////////////////
    var toggleLink = function (e) {
      var $link = $(e.currentTarget),
          blockname = $link.data('block-name'),
          $block = $('div[data-block-name=' + blockname + ']');

      if (blockname === 'block-registration')
        if (!$signInBtn.hasClass('disabled'))
          $signInBtn.addClass('disabled');
        else
          $signInBtn.removeClass('disabled');

      if (blockname === 'block-lost-password')
        if (!$signInBtn.hasClass('hidden'))
          $signInBtn.addClass('hidden');
        else
          $signInBtn.removeClass('hidden');

      if ($link.hasClass('tr-open')) {
        $block.show();
        $link
          .removeClass('tr-open')
          .addClass('tr-close');
      } else {
        $block.hide();
        $link
          .removeClass('tr-close')
          .addClass('tr-open');
      }
    };



    $('select').niceSelect();

    $('.nav-best').on('click', toggleBestPlayers);
    $('.nav-auth').on('click', toggleAuthMenuItem);
    $('.toggle-link').on('click', toggleLink);

    $hamburger.on('click', toggleHamburger);
  });
})(jQuery); 
