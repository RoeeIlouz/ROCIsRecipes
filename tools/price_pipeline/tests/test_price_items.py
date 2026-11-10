import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from price_items import PriceItem, parse_price_full  # noqa: E402

FIXTURE = Path(__file__).parent / "fixtures" / "price_sample.xml"


def _doc(items: str) -> str:
    return f"<Root><ChainID>1</ChainID><Items>{items}</Items></Root>"


def _item(code="1", name="x", price="5.00", unit_price="5.00", weighted="0", uom="unit") -> str:
    parts = [f"<ItemCode>{code}</ItemCode>", f"<ItemName>{name}</ItemName>"]
    if price is not None:
        parts.append(f"<ItemPrice>{price}</ItemPrice>")
    if unit_price is not None:
        parts.append(f"<UnitOfMeasurePrice>{unit_price}</UnitOfMeasurePrice>")
    parts.append(f"<bIsWeighted>{weighted}</bIsWeighted>")
    parts.append(f"<UnitOfMeasure>{uom}</UnitOfMeasure>")
    return "<Item>" + "".join(parts) + "</Item>"


class ParsePriceFullTest(unittest.TestCase):
    def test_parses_utf8_bom_xml(self):
        items = parse_price_full(FIXTURE.read_bytes())
        self.assertEqual(len(items), 19)
        self.assertTrue(all(i.code and i.name for i in items))
        self.assertTrue(all(i.price > 0 for i in items))

    def test_weighted_item_uses_unit_price(self):
        xml = _doc(_item(weighted="1", price="30.00", unit_price="12.5", uom="kg")).encode("utf-8")
        (item,) = parse_price_full(xml)
        self.assertTrue(item.is_weighted)
        self.assertEqual(item.unit_price, 12.5)
        self.assertIsInstance(item, PriceItem)

    def test_skips_zero_negative_and_missing_prices(self):
        xml = _doc(
            _item(code="a", price="0")
            + _item(code="b", price="-1")
            + _item(code="c", price=None)
            + _item(code="d", price="3.90")
        ).encode("utf-8")
        items = parse_price_full(xml)
        self.assertEqual([i.code for i in items], ["d"])

    def test_handles_utf16_xml(self):
        xml = _doc(_item(code="z", name="שוקולד", price="7.5")).encode("utf-16")
        (item,) = parse_price_full(xml)
        self.assertEqual(item.code, "z")
        self.assertEqual(item.name, "שוקולד")

    def test_item_without_unit_price_is_none(self):
        xml = _doc(_item(unit_price=None)).encode("utf-8")
        (item,) = parse_price_full(xml)
        self.assertIsNone(item.unit_price)


if __name__ == "__main__":
    unittest.main()
