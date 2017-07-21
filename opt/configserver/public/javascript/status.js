$( document ).ready(function() {

    function getStatus() {
        $.ajax({
            url: '/status',
            type: 'GET',
            success: function (data) {
                console.log(data);
                var text = "";
                $("#statusArea").empty();
                data.content.forEach(function (element) {
                    $("#statusArea").append(`<p>${element}</p>`);
                }, this);
            }
        });
        setTimeout(getStatus,5000);
    }

    getStatus();
});

$('.upload-btn').on('click', function (){
    $('#upload-input').click();
    service = this.id;
});