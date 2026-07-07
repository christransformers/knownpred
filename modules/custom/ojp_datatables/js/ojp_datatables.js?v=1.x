/**
 * @file
 * OJP Datatables JS.
 */

(function ($, Drupal) {
  "use strict";
  Drupal.behaviors.ojpDatatables = {
    attach: function (context, settings) {
      $(once("ojpDatatables", "table.datatable", context)).each(function () {
        // Set the table width to 100%.
        $(this).css("width", "100%");

        // Store table reference for use in observer
        const $table = $(this);

        // Validate table structure before initializing DataTables
        // Ensure table has proper thead/tbody structure
        if (!$table.find("thead").length) {
          // If no thead, create one from the first row
          const $firstRow = $table.find("tr:first");
          if ($firstRow.length) {
            const $thead = $("<thead></thead>");
            $firstRow.find("td").each(function() {
              const $td = $(this);
              const $th = $("<th></th>").html($td.html());

              // Preserve the hidden-column class if present
              if ($td.hasClass('hidden-column')) {
                $th.addClass('hidden-column');
              }

              // Preserve any other classes
              const tdClasses = $td.attr('class');
              if (tdClasses) {
                $th.addClass(tdClasses);
              }

              // Preserve data attributes (like data-has-facet)
              $.each($td.data(), function(key, value) {
                $th.attr('data-' + key, value);
              });

              $td.replaceWith($th);
            });
            $thead.append($firstRow);
            $table.prepend($thead);
          }
        }

        if (!$table.find("tbody").length) {
          // If no tbody, wrap all non-thead rows in tbody
          const $tbody = $("<tbody></tbody>");
          $table.find("tr").not($table.find("thead tr")).appendTo($tbody);
          $table.append($tbody);
        }

        // Calculate actual column count accounting for colspan
        const $headerRow = $table.find("thead tr:first");
        let expectedColumns = 0;
        $headerRow.find("th, td").each(function() {
          const colspan = parseInt($(this).attr("colspan")) || 1;
          expectedColumns += colspan;
        });

        // Validate all body rows have consistent column counts
        const $bodyRows = $table.find("tbody tr");
        let hasInconsistentColumns = false;

        $bodyRows.each(function() {
          let rowColumns = 0;
          $(this).find("td, th").each(function() {
            const colspan = parseInt($(this).attr("colspan")) || 1;
            rowColumns += colspan;
          });

          if (rowColumns !== expectedColumns) {
            hasInconsistentColumns = true;
          }
        });

        if (hasInconsistentColumns) {
          return; // Skip DataTables initialization for this table
        }

        // Create a mutation observer to watch for data-facets attribute changes
        const facetsObserver = new MutationObserver(function (mutations) {
          mutations.forEach(function (mutation) {
            if (
              mutation.type === "attributes" &&
              mutation.attributeName === "data-facets"
            ) {
              const hasFacets = $table.attr("data-facets") === "true";
              const $existingFacets = $table.prev(".table-facets");

              if (hasFacets && !$existingFacets.length) {
                createTableFacets($table);
              } else if (!hasFacets && $existingFacets.length) {
                $existingFacets.remove();
              }
            }
          });
        });

        // Start observing the table for data-facets changes
        facetsObserver.observe(this, {
          attributes: true,
          attributeFilter: ["data-facets"],
        });

        // Initial facets setup
        if ($table.attr("data-facets") === "true") {
          createTableFacets($table);
        }

        // Configure DataTable options.
        var dataTableOptions = {
          responsive: true,
          paging: $(this).hasClass("datatablePagination") ? true : false,
          searching: $(this).hasClass("datatableSearch") ? true : false,
          // Set DOM layout when pagination is at the top.
          dom: $(this).hasClass("table--pagination-top")
            ? '<"top"lifp><"clear">rt<"clear"><"bottom"ip><"clear">'
            : '<"top"lif>rt<"clear"><"bottom"ip><"clear">',
          // Include hidden columns in search
          columnDefs: [
            {
              targets: "_all",
              searchable: true,
              className: "dt-searchable",
            },
          ],
          // Ensure search works on hidden columns
          search: {
            smart: true,
            searchable: true,
            search: "",
          },
        };

        // Call special condition function for tables with the class 'table--related-topics'
        if ($(this).hasClass("table--related-topics")) {
          handleRelatedTopicsTable($(this));
        } else if ($(this).hasClass("table--outcomes-rbo")) {
          handleProgramOutcomeRBOTable($(this));
        } else if ($(this).hasClass("table--outcome-list")) {
          handleProgramOutcomeListTable($(this));
        } else {
          // Initialize DataTable with the configured options.
          const dataTable = $(this).DataTable(dataTableOptions);

          // After initialization, hide columns with hidden-column class using DataTables API
          $table.find('thead th').each(function(index) {
            if ($(this).hasClass('hidden-column')) {
              dataTable.column(index).visible(false);
            }
          });
        }
      });
      // Handle containers with related topics.
      $(once("ojpDatatables", ".container--related-topics", context)).each(
        function () {
          handleRelatedTopicsContainer($(this));
        }
      );
      $(once("ojpDatatables", "body")).each(function () {
        var $window = $(window);
        var $document = $(document);
        var scrollFromBottom;
        var scrollTimer;

        // Function to calculate the current scroll percentage
        function calculateScrollPercent() {
          return (
            (100 * $window.scrollTop()) /
            ($document.height() - $window.height())
          );
        }

        function updateScrollFromBottom() {
          scrollFromBottom = $document.height() - $window.scrollTop();
        }

        // Initialize scrollFromBottom
        updateScrollFromBottom();

        $window.scroll(function () {
          clearTimeout(scrollTimer);
          scrollTimer = setTimeout(function () {
            if (calculateScrollPercent() > 30) {
              updateScrollFromBottom();
            }
          }, 250);
        });

        $document.on("click", "a.paginate_button", function () {
          if (calculateScrollPercent() > 30) {
            $window.scrollTop($document.height() - scrollFromBottom);
          }
        });
      });
    },
  };

  /**
   * Function to handle tables with the class 'table--related-topics'.
   *
   * @param {jQuery} $table
   *   The table element.
   */
  function handleRelatedTopicsTable($table) {
    // Configure DataTable options.
    let dataTableOptions = {
      responsive: true,
      // Set DOM layout when pagination is at the top.
      dom: '<"top"pli><"clear">rt<"clear"><"bottom"ip><"clear">',
      order: [],
      columnDefs: [
        {
          targets: 1,
          className: "second-column-programs",
          width: "200px",
        },
      ],
    };

    // Initialize DataTable with the configured options.
    const dataTable = $table.DataTable(dataTableOptions);

    // After initialization, hide columns with hidden-column class using DataTables API
    $table.find('thead th').each(function(index) {
      if ($(this).hasClass('hidden-column')) {
        dataTable.column(index).visible(false);
      }
    });
  }

  /**
   * Function to handle tables with the class 'table--outcomes-rbo'.
   *
   * @param {jQuery} $table
   *   The table element.
   */
  function handleProgramOutcomeListTable($table) {
    // Configure DataTable options.
    let dataTableOptions = {
      responsive: true,
      // Set DOM layout when pagination and search are at the top.
      dom: '<"top"pi><"clear">rt<"clear"><"bottom"ip><"clear">',
      order: [],
      // Add a caption to the table with Drupal's translation system.
      initComplete: function (settings, json) {
        let captionText = Drupal.t(
          "Specific Outcomes (select to review details for each outcome)"
        );
        $table.prepend("<caption>" + captionText + "</caption>");
      },
    };

    // Initialize DataTable with the configured options.
    const dataTable = $table.DataTable(dataTableOptions);

    // After initialization, hide columns with hidden-column class using DataTables API
    $table.find('thead th').each(function(index) {
      if ($(this).hasClass('hidden-column')) {
        dataTable.column(index).visible(false);
      }
    });
  }

  /**
   * Function to handle tables with the class 'table--outcomes-rbo'.
   *
   * @param {jQuery} $table
   *   The table element.
   */
  function handleProgramOutcomeRBOTable($table) {
    // Configure DataTable options.
    let dataTableOptions = {
      responsive: {
        details: {
          type: "column",
          target: 0,
        },
      },
      dom: '<"top"pi><"clear">rt<"clear"><"bottom"ip><"clear">',
      order: [],
      columnDefs: [
        {
          targets: -1,
          className: "none",
          responsivePriority: 1,
        },
        {
          targets: 0,
          className: "dtr-control",
          orderable: false,
        },
        {
          targets: -2,
          className: "desktop",
          responsivePriority: 2,
        },
        {
          targets: -3,
          className: "desktop tablet",
          responsivePriority: 3,
        },
      ],
      initComplete: function (settings, json) {
        let captionText = Drupal.t(
          "Specific Outcomes (select to review details for each outcome)"
        );
        $table.prepend("<caption>" + captionText + "</caption>");
      },
    };
    // Initialize DataTable with the configured options.
    const dataTable = $table.DataTable(dataTableOptions);

    // After initialization, hide columns with hidden-column class using DataTables API
    $table.find('thead th').each(function(index) {
      if ($(this).hasClass('hidden-column')) {
        dataTable.column(index).visible(false);
      }
    });
  }

  /**
   * Function to handle the container with the class 'container--related_topics'.
   *
   * @param {jQuery} $container
   *   The container element.
   */
  function handleRelatedTopicsContainer($container) {
    // Find #appliedfilters and .download-csv within the container and detach them
    let $appliedFilters = $container.find("#appliedfilters").hide().detach();
    let $downloadCsv = $container
      .find(".download-csv")
      .css({
        float: "right",
        "margin-top": "0.75rem",
      })
      .hide()
      .detach();

    let intervalId = setInterval(function () {
      let $topElement = $container.find(".dataTables_wrapper .top");
      if ($topElement.length) {
        let $dataTablesLength = $topElement.find("div.dataTables_length");

        if ($appliedFilters.length) {
          $topElement.prepend($appliedFilters.show());
        }

        if ($downloadCsv.length && $dataTablesLength.length) {
          $dataTablesLength.after($downloadCsv.show());
        } else if ($downloadCsv.length) {
          $topElement.append($downloadCsv.show());
        }

        clearInterval(intervalId);
      }
    }, 100);

    // Stop checking after 5 seconds
    setTimeout(function () {
      clearInterval(intervalId);
    }, 5000);
  }

  /**
   * Creates dropdown facets for each column in the table.
   *
   * @param {jQuery} $table
   *   The table element.
   */
  function createTableFacets($table) {
    // Get the first row of headers
    const $headers = $table.find("thead tr:first-child th");

    // Generate unique ID for this table's accordion
    const accordionId = `table-facets-${Math.random()
      .toString(36)
      .substr(2, 9)}`;

    // Create the accordion structure
    const facetsContainer = $("<div>", {
      class:
        "table-facets views-exposed-form usa-accordion js-accordion-container-modified",
      "data-drupal-selector": "views-exposed-form-awards-awards-list-block",
      "aria-label": "accordion-group",
    });

    // Create the accordion heading and button
    const accordionHeading = $("<h2>", {
      class: "usa-accordion__heading js-accordion-heading-modified",
    });

    const accordionDiv = $("<div>", {
      class: "usa-accordion",
    });

    const accordionButton = $("<button>", {
      class: "usa-accordion__button",
      "aria-expanded": "true",
      "aria-controls": accordionId,
      type: "button",
      "data-once": "ojpAccordion",
      text: "Use Search Filters",
    });

    const accordionContent = $("<div>", {
      id: accordionId,
      class: "usa-accordion__content usa-prose ui-widget-content",
    });

    // Position the facets container above the table
    $table.before(facetsContainer);

    // Build the accordion structure
    accordionDiv.append(accordionButton);
    accordionDiv.append(accordionContent);
    accordionHeading.append(accordionDiv);
    facetsContainer.append(accordionHeading);

    // Create a dropdown for each column that has facets enabled
    $headers.each(function (columnIndex) {
      // Check if any cell in this column has facets enabled (including hidden columns)
      const hasFacets =
        $table.find(
          `tbody tr td:nth-child(${columnIndex + 1})[data-has-facet="true"]`
        ).length > 0;
      if (!hasFacets) {
        return;
      }

      const columnHeader = $(this).text().trim();
      const uniqueValues = new Set();
      const orderedValues = [];

      // Get all values from this column (including hidden cells)
      $table
        .find(`tbody tr td:nth-child(${columnIndex + 1})`)
        .each(function () {
          const value = $(this).text().trim();
          if (!uniqueValues.has(value)) {
            uniqueValues.add(value);
            orderedValues.push(value);
          }
        });

      // Create the dropdown
      const selectId = `facet-select-${columnIndex}`;
      const select = $("<select>", {
        class: "usa-select facet-select",
        "data-column": columnIndex,
        id: selectId,
      });

      // Add the "Any" option
      select.append(
        $("<option>", {
          value: "",
          text: "Any",
        })
      );

      // Add all values in their original order
      orderedValues.forEach((value) => {
        select.append(
          $("<option>", {
            value: value,
            text: value,
          })
        );
      });

      // Create a label for the dropdown
      const label = $("<label>", {
        class: "facet-label",
        text: columnHeader,
        for: selectId,
      });

      // Create a wrapper div for positioning
      const wrapper = $("<div>", {
        class: "facet-wrapper",
        "data-column": columnIndex,
      })
        .append(label)
        .append(select);

      // If the column is hidden, initially hide the facet wrapper
      if ($(this).hasClass("hidden-column")) {
        wrapper.addClass("hidden-facet");
      }

      // Append the wrapper to the accordion content
      accordionContent.append(wrapper);

      // Handle change event
      select.on("change", function () {
        // Get reference to the DataTable instance
        const dataTable = $table.DataTable();

        // Get all current filter values
        const filters = {};
        accordionContent.find("select.facet-select").each(function () {
          const value = $(this).val();
          const column = $(this).data("column");
          if (value !== "") {
            filters[column] = value;
          }
        });

        // Clear any existing custom filtering function
        $.fn.dataTable.ext.search.pop();

        // Add custom filtering function if we have filters
        if (Object.keys(filters).length > 0) {
          $.fn.dataTable.ext.search.push(function (settings, data, dataIndex) {
            // Only apply to this specific table
            if (settings.nTable !== $table[0]) {
              return true;
            }

            // Check each filter
            return Object.entries(filters).every(([column, value]) => {
              // Get the text value from the cell (data array is 0-indexed, columns are 1-indexed)
              const cellValue = data[parseInt(column)].trim();
              return cellValue === value;
            });
          });
        }

        // Redraw the table with the filters applied
        dataTable.draw();
      });
    });

    // Only add Clear Filters button if we have any facets
    if (accordionContent.find(".facet-wrapper").length > 0) {
      const clearFiltersWrapper = $("<div>", {
        class: "clear-filters-wrapper",
      });

      const clearFiltersButton = $("<button>", {
        class: "usa-button clear-filters-button",
        text: "Clear Filters",
      });

      clearFiltersButton.on("click", function () {
        // Get reference to the DataTable instance
        const dataTable = $table.DataTable();

        // Reset all select elements to their default "Any" option
        accordionContent.find("select.facet-select").each(function () {
          $(this).val("");
        });

        // Clear any filtering function
        $.fn.dataTable.ext.search.pop();

        // Redraw the table
        dataTable.draw();
      });

      clearFiltersWrapper.append(clearFiltersButton);
      accordionContent.append(clearFiltersWrapper);
    }

    // Update the mutation observer to handle hidden facets
    const observer = new MutationObserver(function (mutations) {
      mutations.forEach(function (mutation) {
        if (
          mutation.type === "attributes" &&
          mutation.attributeName === "class"
        ) {
          const $element = $(mutation.target);
          const columnIndex = $element.index();
          const $facet = accordionContent.find(
            `.facet-wrapper[data-column="${columnIndex}"]`
          );

          if ($element.hasClass("hidden-column")) {
            // Add hidden-facet class if the column is hidden
            $facet.addClass("hidden-facet");
          } else {
            // Remove hidden-facet class if the column is visible
            $facet.removeClass("hidden-facet");
          }
        }
      });
    });

    // Observe all th elements for class changes
    $headers.each(function () {
      observer.observe(this, {
        attributes: true,
        attributeFilter: ["class"],
      });
    });
  }
})(jQuery, Drupal);
