$(document).ready(function(){
  var $alertSignUp = $('.alert-sign-up');
  var $alertLogin = $('.alert-login');
  var $alertNewFood = $('.alert-new-food');
  var $addDetail = $('#add-detail').html();

  function postUser(data) {
    return $.ajax({
        type: 'POST',
        url:  '/new_user',
        data : data,
        dataType: "json"
    })
  }

  function postLogin(data) {
    return $.ajax({
        type: 'POST',
        url:  '/login',
        data : data,
        dataType: "json"
    })
  }

  function postNewFood(data) {
    return $.ajax({
        type: 'POST',
        url:  '/food/new',
        data : data,
        dataType: "json"
    })
  }

  $('.btn-sign-up').on('click', function (){
    var serialized = $('.sign-up-form').serialize();

    postUser(serialized).done(function(result) {
        console.log("done");
        console.log(result);
        if (result.code < 0) {
            $alertSignUp.removeClass('alert-success');
            $alertSignUp.addClass('alert-warning');
            // $alertSignUp.find('.alert-message').empty();
            $alertSignUp.find('.alert-message').html(result.message);
            $alertSignUp.show();
        } else {
            $alertSignUp.removeClass('alert-warning');
            $alertSignUp.addClass('alert-success');
            // $alertSignUp.find('.alert-message').empty();
            $alertSignUp.find('.alert-message').html(result.message);
            $alertSignUp.show();
        }
    })
    .fail(function() {
        console.log( "error" );
    })
    .always(function() {
        console.log( "always" );
    });
  });

  $('.btn-login').on('click', function (){
    var serialized = $('.login-form').serialize();

    postLogin(serialized).done(function(result) {
        console.log("done");
        console.log(result);
        if (result.code < 0) { //ログイン失敗
            $alertLogin.removeClass('alert-success');
            $alertLogin.addClass('alert-warning');
            // $alertLogin.find('.alert-message').empty();
            $alertLogin.find('.alert-message').html(result.message);
            $alertLogin.show();
        } else { // ログイン成功
            $alertLogin.removeClass('alert-warning');
            $alertLogin.addClass('alert-success');
            // $alertLogin.find('.alert-message').empty();
            $alertLogin.find('.alert-message').html(result.message);
            $alertLogin.show();
            window.location.href = "/menu";
        }
    })
    .fail(function() {
        console.log( "error" );
    })
    .always(function() {
        console.log( "always" );
    });
  });

  $('.btn-new-food').on('click', function (){
    var serialized = $('.new-food-form').serialize();

    postNewFood(serialized).done(function(result) {
        console.log("done");
        console.log(result);
        if (result.code < 0) { //ログイン失敗
            $alertNewFood.removeClass('alert-success');
            $alertNewFood.addClass('alert-warning');
            // $alertNewFood.find('.alert-message').empty();
            $alertNewFood.find('.alert-message').html(result.message);
            $alertNewFood.show();
        } else { // ログイン成功
            $alertNewFood.removeClass('alert-warning');
            $alertNewFood.addClass('alert-success');
            // $alertNewFood.find('.alert-message').empty();
            $alertNewFood.find('.alert-message').html(result.message);
            $alertNewFood.show();
            window.location.href = "/details/edit/" + result.data;
        }
    })
    .fail(function() {
        console.log( "error" );
    })
    .always(function() {
        console.log( "always" );
    });
  });

  $('.alert-close').on('click', function () {
    console.log('here');
    var $this = $(this);
    $this.parents('.alert').hide();
  });

  $('.btn-add-detail').on('click', function () {
    console.dir($addDetail);
    $('.add-box').html($addDetail);
  });

  $('.btn-save').on('click', function () {
    $.ajax({
      url:'/detail/number/',
      type:'POST',
      data:{
          'number':$(this).parents('tr').find('input.number').val(),
          'detailId':$(this).parents('tr').data('detail-id')
      },
      dataType: "json"
    })
    .done(function(result){
        console.log(result);
        window.location.href = "/details/edit/" + result.data;
    })
    .fail(function(result){
        console.log(result);
    });
  });
});
