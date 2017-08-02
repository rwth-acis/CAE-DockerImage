var service;

$('.upload-btn').on('click', function (){
    $('#upload-input').click();
    service = this.id;
});

$('.restart-btn').on('click', function(){
  service = this.id;
  $.ajax({
    url: '/restart/' + service,
    type: 'GET',
    success: function(data){
      alert(`Stopping ${service}`);
    }
  });
});

$('.stop-btn').on('click', function(){
  service = this.id;
  $.ajax({
    url: '/stop/' + service,
    type: 'GET',
    success: function(data){

    }
  });
});

$('#modelPropertyFormSubmit').on('click', function() {
  var formData = $( "#modelPropertyForm" ).serializeArray();
  console.log(formData);
  $.ajax({
    url: '/upload/model/detailed',
    type: 'POST',
    data: JSON.stringify(formData),
    contentType: 'application/json',
    success: function(data) {
      console.log("Success");
    }
  });
});

$('#upload-input').on('change', function(){

  var files = $(this).get(0).files;

  if (files.length > 0){
    var formData = new FormData();
    for (var i = 0; i < files.length; i++) {
      var file = files[i];
      formData.append('uploads[]', file, file.name);
    }

    $.ajax({
      url: '/upload/'+service,
      type: 'POST',
      data: formData,
      processData: false,
      contentType: false,
      success: function(data){
          console.log('upload successful!\n' + data);
      }
    });
  }
});