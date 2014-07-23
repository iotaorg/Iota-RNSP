$(document).ready(function () {

    var list_endpoint = $('#indicators_container').attr('data-list-endpoint'),
    modal_endpoint = $('#indicators_container').attr('data-modal-endpoint');

    $('#indicators_container.end_user_indicator').on('click', 'button.follow-indicator', {}, function () {
        var $me = $(this),
            indicator_id = $me.closest('tr[indicator-id]').attr('indicator-id');

        $me.attr('disabled', 'disabled');

        $.ajax({
            type: 'POST',
            dataType: 'json',
            data: {
                'end_user_indicator.create.indicator_id': indicator_id
            },
            url: list_endpoint,
            success: function (data, textStatus, jqXHR) {

                $me
                    .text($me.closest('td[data-edit-txt]').attr('data-edit-txt'))
                    .removeClass('btn-primary').addClass('btn-warning')
                    .removeClass('follow-indicator').addClass('edit-pref')
                    .attr('data-end_user_indicator', data.id);

            },
            complete: function (data) {
                $me.removeAttr('disabled');
            }
        });
    });


    $('#indicators_container.end_user_indicator').on('click', 'button.edit-pref', {}, function () {
        var $me = $(this),
            end_user_indicator_id = $me.attr('data-end_user_indicator');

        $('#modal_edit .remote-content').html('<div class="loading" style="margin: 15px auto; width: 32px; "></div>');

        $('#modal_edit').modal();

        $.ajax({
            type: 'GET',
            dataType: 'html',
            url: modal_endpoint + end_user_indicator_id,
            success: function (data, textStatus, jqXHR) {
                $('#modal_edit').modal( {
                    backdrop: true
                } );

                $('#modal_edit .remote-content').html(data);

                $('#modal_edit .remote-content .stop-follow').click(function(){_delete_item(end_user_indicator_id)});


            },
            complete: function (data) {}
        });


    });

    function _delete_item(end_user_indicator_id){

        $('#modal_edit .remote-content').html('<div class="loading" style="margin: 15px auto; width: 32px; "></div>');

        $.ajax({
            type: 'DELETE',
            url: list_endpoint + '/' + end_user_indicator_id,
            success: function (data, textStatus, jqXHR) {

                $('#modal_edit .remote-content').html($('#stop_follow').html());



                $('#modal_edit').on('hidden.bs.modal', function (e) {
                    location.reload();
                })

            },
            complete: function (data) {

            }
        });




    }


});