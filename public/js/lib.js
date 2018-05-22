function ajax(method, form, url, callback, error) {
    var xhr = new XMLHttpRequest()
    xhr.onreadystatechange = () => { 
        if (xhr.readyState === 4) {
            if (xhr.status < 300 && callback) {
                callback(xhr)
            } else if (xhr.status >= 300 && error) {
                error(xhr)
            }
        }
    }
    xhr.open(method, url, true)
    if (form) {
        xhr.setRequestHeader('Content-type', 'application/json')
    }
    xhr.send(form)
}
function get(url, callback, error) { return ajax('GET', null, url, callback, error) }
function post(url, form, callback, error) { return ajax('POST', JSON.stringify(form), url, callback, error) }