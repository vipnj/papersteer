package tabinda.demo
{
public class DeferredLine
	{
		public static function DeferredLine()
		{
			deferredLineArray = new Array(size);
			for (var i:int = 0; i < size; i++)
			{
				deferredLineArray[i] = new DeferredLine();
			}
		}

		public static function AddToBuffer(s:Vector3, e:Vector3, c:Color):void
		{
			if (index < size)
			{
				deferredLineArray[index].startPoint = s;
				deferredLineArray[index].endPoint = e;
				deferredLineArray[index].color = c;
				index++;
			}
			else
			{
				trace("overflow in deferredDrawLine buffer");
			}
		}

		public static function DrawAll():void
		{
			// draw all lines in the buffer
			for (var i:int = 0; i < index; i++)
			{
				var dl:DeferredLine = deferredLineArray[i];
				Drawing.iDrawLine(dl.startPoint, dl.endPoint, dl.color);
			}

			// reset buffer index
			index = 0;
		}

		var startPoint:Vector3;
		var endPoint:Vector3;
		var color:Color;

		static var index:int = 0;
		const size:int = 3000;
		static deferredLine:Array;
	}
	}