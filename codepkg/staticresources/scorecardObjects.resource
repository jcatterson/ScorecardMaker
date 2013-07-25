var card;
var titleEdit;
var rowEdit;
var cellEdit;
var $j;

jQuery(function() {
    $j = jQuery.noConflict();
    titleEdit = $j('#titleEditSection');
    rowEdit = $j('#rowEditSection');
    cellEdit = $j('#cellEditSection');

    $j( ".draggable" ).draggable({ revert: true, revertDuration: 0});
    $j('.rowDraggable').draggable({ revert: true, revertDuration: 0});
    makeScorecardRowDroppable( $j('.scorecardRow') );

	if( !loadScorecard() ) {
        makeScorecardDroppable( $j('.scorecardPage') );

	}

    $j('#saveBtn').click( function() {
		var temp = card.tableMarkup;
		card.tableMarkup = null;
		nullOutTitlesParent( card.mainTitle );
		console.log( JSON.stringify( card ) );
        saveCard( JSON.stringify( card ) );
    });
});

function Scorecard( tableMarkup ) {
    this.tableMarkup = tableMarkup;
    this.mainTitle;
	this.type = 'Standard';
    this.cols = [];
    
    this.setTitle = function( title ) {
        this.mainTitle = title;
        this.rebuild();
    }
    
    this.rebuild = function() {
        this.tableMarkup.html('');
        var titles = this.mainTitle.getChildrenAndGrandChildren();
        console.log(titles);
        for( var row = 0; row < titles.length; row++ ) {
            var rowMarkup = $j( '<tr>' );
			var topLeftCell = $j('<td>').addClass('row');
			appendStyle( topLeftCell, titles[row][0].css );
			rowMarkup.append( topLeftCell );
            for( var col = 0; col < titles[row].length; col++ ) {
                titles[row][col].markup().appendTo( rowMarkup );
            }
            this.tableMarkup.append( rowMarkup );
        }
        
        var rowMarkup = $j('<tr>');
        for( var row =0; row < this.cols.length; row++ ) {
            var rowObj = this.cols[row];
            rowMarkup.append( rowObj.markup() );
            
            var lastLayer = titles.length-1;
            for( var title =0; title < titles[lastLayer].length; title++ ) {
                var cell = titles[lastLayer][title].getCell( rowObj );
                rowMarkup.append( cell.markup() );
            }
            this.tableMarkup.append( rowMarkup );
            rowMarkup = $j('<tr>');
        }
        this.tableMarkup.append( rowMarkup );
        
        var appendableRow = $j('<tr><td style="height:25px;width:65px"></tr>');
        makeScorecardRowDroppable( appendableRow );
        this.tableMarkup.append( appendableRow );
    }
    
    this.addRow = function( row ) {
        console.log( row.rowName );
        this.cols.push( row );
        this.rebuild();
    }
}

function Table() {
	this.queries = [];
	
	this.buildQueryGroups = function( cells ) {
		console.log( cells );
		for(var cell in cells ) {
			var c = cells[cell];
			console.log('what is the cell?');
			console.log( c );
			console.log( cell );
			console.log( cells );
			var query = new QueryGroup( c.table, [c], c.caseCondition  );
			this.queries.push( query );
		}
	}
}

function QueryGroup(objectType, columns, condition) {
	this.columns = columns;
	this.objectType = objectType;
	this.condition = condition;
}

function Title( name, card, parent, css ) {
    this.label = name;
    this.css = (css === null ? '' : css);
    this.subtitles = [];
    this.parent = parent;
    this.cells = {};
	this.table = new Table();

	this.buildTable = function() {

		console.log('what are the cells');
		console.log( this.cells );
		this.table.buildQueryGroups( this.cells );
	}
    
    this.colspan = function() {
        if( this.isLeaf() ) {
            return 1;
        }
        var allMyChildren = this.getChildrenAndGrandChildren();
        var lastLayer = allMyChildren[ allMyChildren.length - 1];
        return lastLayer.length;
    }
    
    this.addChild = function( childTitle ) {
        this.subtitles.push( childTitle );
        card.rebuild();
    }
    
    this.isLeaf = function() {
        return this.subtitles.length == 0;
    }
    
    this.markup = function() {
        var cellData = $j('<td>').html( this.label );
        var brother = $j('<td rowspan="2"/>');
        var row = $j('<tr>');
        row.append( cellData );
        row.append( brother );
        
        var children = $j('<tr/>');
        children.append( $j('<td/>') );
        
        var markup = $j('<table class="titlesTable" style="width:100%">');
            markup.append( row ).append( children );

        if( this.isLeaf() ) {
            makeTitleDroppable( new PotentialTitle( new Title('Child of ' + this.label, card, this ), children ) );
        }
        makeTitleDroppable( new PotentialTitle( new Title('Sibling of ' + this.label, card, this.parent), brother ) );
        html = $j('<td/>').append( markup ).prop('colspan', this.colspan()).addClass( 'title' );

        this.makeTitleSelectable( html );
		appendStyle( html, this.css );
        return html;
    }
    
    this.getChildrenAndGrandChildren = function() {
        var titles = [[]];
        this.buildGrandchildrenStructure( titles, 0 );
        return titles;
    }
    
    this.buildGrandchildrenStructure = function(titles, layer) {
        if( titles.length <= layer) {
            console.log('new layer');
            titles.push( [] );
        }
        titles[layer++].push( this );
        if( this.isLeaf() ) {
            return;
        }
        else {
            for(var i = 0; i < this.subtitles.length; i++) {
                this.subtitles[i].buildGrandchildrenStructure(titles, layer);
            }
        }
    }
    
    this.getCell = function( row ) {
        if( !this.cells[ row.name ] && row.name ) {
            var c = new Cell( row.name );
            this.cells[ row.name ] = c;
        }
		else if( !row.name ) {
			return new Cell();
		}
        return this.cells[ row.name ];
    }
    
    this.makeTitleSelectable = function( html ) {
        var title = this;
        html.selectable({
            selected: function( event, ui ) {
                $j('.selected').removeClass('selected');
                $j(this).addClass('selected');
                
                var editSection = titleEdit.show();
                cellEdit.hide();
                rowEdit.hide();
                editSection.find('#titleName').val( title.label );
                editSection.find('#titleStyle').val( title.css );
                
                $j('#saveTitle').click(title, function(eventItem){
                    $j(this).unbind('click');
                    titleEdit.hide();
                    eventItem.data.label = $j('#titleName').val();
					eventItem.data.css = $j('#titleStyle').val();
					console.log( $j('#titleStyle').val() );
					console.log( eventItem.data );
					card.rebuild();

                });
            }
        });
    }
}
    
function PotentialTitle( title, markup ) {
    this.title = title;
    this.markup = markup;
}

function Cell( alias ) {
    this.table = '';
    this.recordType = '';
    this.field = '';
    this.caseCondition = '';
	this.name = alias;
	this.htm = '';
    
    this.markup = function() {
        var markup = $j('<td>').addClass('cell');
        markup.append('<table><tr><td/></tr></table>');
        this.setClickEvent( markup );
		htm = markup;
        return markup;
    }
    

	this.setClickEvent = function( markup ) {
		markup.click( this, function(eventItem) {
                cellEdit.show();
                rowEdit.hide();
                titleEdit.hide();
                var theCell = eventItem.data;

				cellEdit.find('#tableName').val( theCell.table  );
				cellEdit.find('#type').val( theCell.recordType  );
				cellEdit.find('#field').val( theCell.field );
				cellEdit.find('#condition').val( theCell.caseCondition );

                $j('#saveCell').click( theCell, function(eventItem) {
					$j(this).unbind('click');
                    cellEdit.hide();

					console.log( eventItem.data );
                    eventItem.data.table = $j('#tableName').val();
                    eventItem.data.recordType = $j('#type').val();
                    eventItem.data.field = $j('#field').val();
                    eventItem.data.caseCondition = $j('#condition').val();

					console.log( eventItem.data );
				
					card.rebuild();
                });

		});

	}
}

function Row( rowName, card  ) {
    this.label = rowName;
    this.name = '';
    this.css = '';
	this.type = '';
    
    this.markup = function() {
        var cell = $j('<td>');
        cell.addClass('row');
        cell.append('<table style="width:100%;height:100%"><tr><td>' + this.label + '</td></tr></table>');
        this.makeRowSelectable( cell );
		appendStyle( cell, this.css );
        return cell;
    }
    
    this.makeRowSelectable = function( html ) {
        var row = this;
        html.selectable({
            selected: function( event, ui ) {
                $j('.selected').removeClass('selected');
                $j(this).addClass('selected');
                
                var editSection = rowEdit.show();
                titleEdit.hide();
                cellEdit.hide();
                
                editSection.find('#rowName').val( row.label );
                editSection.find('#rowStyle').val( row.css );
                editSection.find('#rowAlias').val( row.name );
				editSection.find('#rowType').val( row.type );
                
                $j('#saveRow').click(row, function(eventItem){
                    $j(this).unbind('click');
                    eventItem.data.label = $j('#rowName').val();
					eventItem.data.name = $j('#rowAlias').val();
					eventItem.data.css = $j('#rowStyle').val();
					eventItem.data.type = $j('#rowType').val();

                    rowEdit.hide();
					card.rebuild();
                });
            }
        });
    }    
}


function makeTitleDroppable( item ) {
    var potentialTitle = item;
    item.markup.droppable({
        drop: function( event, ui ) {
            var parent = potentialTitle.title.parent;
            var child = potentialTitle.title;
            if( parent !== null ) {
                parent.addChild( child );
            }
            else {
				console.log('this should only happen once');
                var oldMainTitle = card.mainTitle;
                var mainTitle = new Title('', card, null);
                mainTitle.css = 'display:none;';
                card.setTitle( mainTitle );
                oldMainTitle.parent = mainTitle;
                potentialTitle.title.parent = mainTitle;
                mainTitle.addChild( oldMainTitle );
                mainTitle.addChild( potentialTitle.title );
                
            }
        },
        accepts: 'draggable',
        hoverClass: 'dropMe',
		tolerance: 'pointer'
    });
}

function makeScorecardDroppable( item ) {
    item.droppable({
        drop: function( event, ui ) {
			console.log( $j(this).children()[0] );
            card = new Scorecard( $j(this).children().eq(0) );
            card.setTitle( new Title('New Title', card, null) );
			$j(this).droppable('destroy');
        },
        accepts: 'draggable',
        hoverClass: 'dropMe'
    });
}

function makeScorecardRowDroppable( item ) {
    item.droppable({
        drop: function( event, ui ) {
            if( !card ) {
                alert('You have to create a card first');
            }
            else {
                var row = new Row( "New Row", card);
                card.addRow( row );
            }
        },
        accept: '.rowDraggable',
        hoverClass: 'dropMe'
    });
}

function nullOutTitlesParent( title ) {
	titles = title.getChildrenAndGrandChildren();
    for( var row = 0; row < titles.length; row++ ) {
        for( var col = 0; col < titles[row].length; col++ ) {
            titles[row][col].parent = null;
			titles[row][col].buildTable();
        }
	}
}

function styling( css ) {
	if( !css ) return;
    var cssStyle = {};
    var style = css.split(';');
    for( var i in style ) {
        var attr_val = style[i].split(':');
        console.log(attr_val);
        if( attr_val.length == 2 ) {
            cssStyle[ attr_val[0] ] = attr_val[1];
        }
    }
    return cssStyle;
}

function appendStyle( htm, css ) {
    var css = this.styling( css );
    for( var key in css ) {
        htm.css( key, css[key] );
    }
}

function loadScorecard() {
	var meta = $j('[id$="scorecardDetails"]').val();
	if( meta !== '' ) {
        var meta = JSON.parse( meta );
		var markup = $j('.titleSection');
        card = new Scorecard( markup );

        card.mainTitle = loadMainTitle( meta.mainTitle );
		card.cols = loadFieldsToDisplay( meta.cols  );

        card.rebuild();
		return true;
	}
	return false;
}

function loadFieldsToDisplay( fieldsToDisplayObj  ) {
	var fieldsDisplayed = [];
	for( var i in fieldsToDisplayObj ) {
		var rowObj = fieldsToDisplayObj[i];
		var row = new Row( rowObj.label, card );
		row.name = rowObj.name;
		row.type = (rowObj.type === null ? '' : rowObj.type );
		row.css = (rowObj.css === null ? '' : rowObj.css);
		fieldsDisplayed.push( row );
	}
	return fieldsDisplayed;
}

function loadMainTitle( mainTitleObj ) {
	var mainTitle = new Title( mainTitleObj.label, card, null, mainTitleObj.css );
	mainTitle.subtitles = loadSubTitles( mainTitleObj.subtitles, mainTitle );
	mainTitle.cells = loadCells( mainTitleObj.cells );
	return mainTitle;
}

function loadSubTitles( subTitles, parent ) {
	var titles = [];
	console.log( subTitles );
	for( var i in subTitles ) {
		var title = subTitles[i];
		var loadedTitle = new Title( title.label , card, parent, title.css );
		loadedTitle.cells = loadCells( title.cells  );
		loadedTitle.subtitles = loadSubTitles( title.subtitles, loadedTitle );
		titles.push( loadedTitle );
	}
	return titles;
}

function loadCells( cells ) {
	mappedCells = {};
	for( var key in cells ) {
		var cellObj = cells[key];
		var loadedCell = new Cell( cellObj.name );
		loadedCell.recordType = (cellObj.recordType === null ? '' : cellObj.recordType);
		loadedCell.field = (cellObj.field === null ? '' : cellObj.field);
		loadedCell.caseCondition = (cellObj.caseCondition === null ? '' : cellObj.caseCondition);
		loadedCell.table = (cellObj.table === null ? '' : cellObj.table);
		console.log( 'what is the type?' );
		console.log( type );
		mappedCells[ loadedCell.name ] = loadedCell;
	}
	return mappedCells;
}