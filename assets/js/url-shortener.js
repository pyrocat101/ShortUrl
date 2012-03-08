$(document).ready(function() {
    var showError = function(str) {
        $('#short-url-label').remove();
        $('#input-url').focus().select();
        if ($('#input-error').length !== 0) {
            $('#input-error>h4.alert-heading').text(str);
        } else {
            $('<div>').addClass('alert')
                      .addClass('alert-error')
                      .attr('id', 'input-error')
                      .append($('<a>').addClass('close')
                                      .attr('data-dismiss', 'alert')
                                      .html('&times;'))
                      .append($('<h4>').addClass('alert-heading')
                                       .html(str))
                      .hide()
                      .appendTo($('#form-url'))
                      .slideDown();
        }
    };
    var showShortUrl = function(str) {
        $('#input-error').remove();
        var setShortUrl = function(elem, shortUrl) {
            $('#input-url').attr('value', 'http://' + shortUrl)
                           .focus().select();
            return elem.text('Your shortened URL is: ')
                       .append($('<a>')
                       .attr('href', 'http://' + shortUrl)
                       .text(shortUrl));
        };
        if ($('#short-url-label').length !== 0) {
            setShortUrl($('#short-url-label'), str);
        } else {
            var elem = $('<div>').addClass('alert')
                                 .addClass('alert-success')
                                 .attr('id', 'short-url-label');
            setShortUrl(elem, str).hide()
                                  .appendTo($('#form-url'))
                                  .slideDown();

        }
    };
    $('#input-url').on('click', function() {
        $(this).focus().select();
    });
    $('#form-url').on('submit', function() {
        var re, url;
        url = $.trim($('#input-url').attr('value'));
        re = /^(?:(?:ht|f)tp(?:s?)\:\/\/|~\/|\/)?(?:\w+:\w+@)?((?:(?:[-\w\d{1-3}]+\.)+(?:com|org|net|gov|mil|biz|info|mobi|name|aero|jobs|edu|co\.uk|ac\.uk|it|fr|tv|museum|asia|local|travel|[a-z]{2}))|((\b25[0-5]\b|\b[2][0-4][0-9]\b|\b[0-1]?[0-9]?[0-9]\b)(\.(\b25[0-5]\b|\b[2][0-4][0-9]\b|\b[0-1]?[0-9]?[0-9]\b)){3}))(?::[\d]{1,5})?(?:(?:(?:\/(?:[-\w~!$+|.,=]|%[a-f\d]{2})+)+|\/)+|\?|#)?(?:(?:\?(?:[-\w~!$+|.,*:]|%[a-f\d{2}])+=?(?:[-\w~!$+|.,*:=]|%[a-f\d]{2})*)(?:&(?:[-\w~!$+|.,*:]|%[a-f\d{2}])+=?(?:[-\w~!$+|.,*:=]|%[a-f\d]{2})*)*)*(?:#(?:[-\w~!$ |\/.,*:;=]|%[a-f\d]{2})*)?$/i;
        if (re.test(url)) {
            $.getJSON('/1?url=' + url).success(function(data) {
                if (data.error) {
                    showError(data.error); }
                else
                    showShortUrl(data.shortUrl);
            }).error(function (data) {
                console.log(data);
                showError('Get short URL failed! Please try again.');
            });
        } else {
            showError('Invalid URL!');
        }
        return false;
    });
});
