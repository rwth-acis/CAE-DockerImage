$( document ).ready(function() {
  $.ajax({
    url: '/status',
    type: 'GET',
    success: function(data){
      console.log(data);
      var text = "";
      data.content.forEach(function(element) {
          $("#statusArea").append(`<p>${element}</p>`);
      }, this);
    }
  });
});

$('.upload-btn').on('click', function (){
    $('#upload-input').click();
    service = this.id;
});