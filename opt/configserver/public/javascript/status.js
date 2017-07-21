$( document ).ready(function() {
  $.ajax({
    url: '/status',
    type: 'GET',
    success: function(data){
      console.log(data);
      $('#statusArea').text(data);
    }
  });
});

$('.upload-btn').on('click', function (){
    $('#upload-input').click();
    service = this.id;
});