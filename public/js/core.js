$(document).ready(() => {
    $('tr.row-data').click(function() {
        var emailId = $(this).data('email-id');
        $(`tr.row-meta[data-email-id=${emailId}]`).slideToggle();
        $(`tr.row-meta[data-email-id=${emailId}] div`).slideToggle();
    })
})