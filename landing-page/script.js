// Jronix Post Landing Page Interactive Logic
document.addEventListener('DOMContentLoaded', () => {
  // 1. Interactive Tabs in App Showcase
  const tabButtons = document.querySelectorAll('.tab-btn');
  const tabPanels = document.querySelectorAll('.tab-panel');

  tabButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      const targetTab = btn.getAttribute('data-tab');

      // Update button active state
      tabButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      // Update panel visibility
      tabPanels.forEach(panel => {
        if (panel.id === `tab-${targetTab}`) {
          panel.classList.add('active');
        } else {
          panel.classList.remove('active');
        }
      });
    });
  });

  // 2. FAQ Accordion
  const accordionItems = document.querySelectorAll('.accordion-item');

  accordionItems.forEach(item => {
    const trigger = item.querySelector('.accordion-trigger');
    const content = item.querySelector('.accordion-content');

    trigger.addEventListener('click', () => {
      const isActive = item.classList.contains('active');

      // Close all items
      accordionItems.forEach(i => {
        i.classList.remove('active');
        const c = i.querySelector('.accordion-content');
        if (c) c.style.maxHeight = null;
      });

      // Toggle current item
      if (!isActive) {
        item.classList.add('active');
        content.style.maxHeight = content.scrollHeight + 'px';
      }
    });
  });

  // Open the first FAQ item by default
  if (accordionItems.length > 0) {
    const firstItem = accordionItems[0];
    firstItem.classList.add('active');
    const firstContent = firstItem.querySelector('.accordion-content');
    if (firstContent) {
      firstContent.style.maxHeight = firstContent.scrollHeight + 'px';
    }
  }

  // 3. Copy CLI Snippet Button
  const copyBtn = document.getElementById('copyCliBtn');
  if (copyBtn) {
    copyBtn.addEventListener('click', () => {
      const cliCode = "git clone https://github.com/ranasheikh64/Post-Lite.git && flutter run -d macos";
      navigator.clipboard.writeText(cliCode).then(() => {
        const originalText = copyBtn.textContent;
        copyBtn.textContent = 'Copied! ✓';
        copyBtn.style.background = '#10b981';
        copyBtn.style.color = '#ffffff';

        setTimeout(() => {
          copyBtn.textContent = originalText;
          copyBtn.style.background = '';
          copyBtn.style.color = '';
        }, 2000);
      }).catch(err => {
        console.error('Failed to copy: ', err);
      });
    });
  }

  // 4. Mobile Menu Toggle
  const mobileToggle = document.getElementById('mobileToggle');
  const navbar = document.getElementById('navbar');

  if (mobileToggle && navbar) {
    mobileToggle.addEventListener('click', () => {
      navbar.classList.toggle('open');
    });

    // Close menu when clicking a link
    document.querySelectorAll('.nav-link').forEach(link => {
      link.addEventListener('click', () => {
        navbar.classList.remove('open');
      });
    });
  }

  // 5. Navbar dynamic elevation on scroll
  window.addEventListener('scroll', () => {
    if (window.scrollY > 40) {
      navbar.style.background = 'rgba(8, 9, 13, 0.92)';
      navbar.style.boxShadow = '0 10px 30px rgba(0, 0, 0, 0.5)';
    } else {
      navbar.style.background = 'rgba(8, 9, 13, 0.75)';
      navbar.style.boxShadow = 'none';
    }
  });
});
