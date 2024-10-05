require 'minitest/autorun'
require 'minibidi'

class ExampleTest < Minitest::Test
  def test_firefox_example
    Minibidi::Firefox.launch do |browser|
      context = browser.create_browsing_context
      context.navigate("https://github.com/YusukeIwaki")
      data = context.capture_screenshot(origin: :viewport, format: { type: :png })

      open('YusukeIwaki.png', 'wb') do |f|
        f.write(data)
      end
    end
  end

  def test_firefox_example_with_evaluate_javascript
    script = <<-JAVASCRIPT
    let repos = document.querySelectorAll('li.mb-3.d-flex');
    let maxStars = 0;
    let maxRepo = null;

    repos.forEach(repo => {
      let starsElement = repo.querySelector('a.pinned-item-meta.Link--muted');  // Get the element containing the stars
      if (starsElement) {
        let starsText = starsElement.innerText.trim();
        let stars = parseInt(starsText.replace(',', ''), 10);  // Parse the stars count and remove commas
        if (stars > maxStars) {
          maxStars = stars;
          maxRepo = repo;
        }
      }
    });

    if (maxRepo) {
      maxRepo.querySelector('a.text-bold').click();  // Click on the repository with the highest stars count
    }
    JAVASCRIPT

    Minibidi::Firefox.launch do |browser|
      context = browser.create_browsing_context
      context.navigate("https://github.com/YusukeIwaki")
      sleep 2
      context.default_realm.script_evaluate(script)
      sleep 3
      data = context.capture_screenshot(origin: :viewport, format: { type: :png })
      open('YusukeIwaki.png', 'wb') do |f|
        f.write(data)
      end
    end
  end
end
